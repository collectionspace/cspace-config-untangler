# frozen_string_literal: true

require_relative "fields/definition/parser"

module CspaceConfigUntangler
  class RecordType
    include CCU::Iterable

    # Names of record types we don't interact with as first-class data-layer
    # entities, which are thus ignored by this application
    IGNORED = %w[account all audit authrole authority batch batchinvocation
      blob contact export idgenerator object procedure relation
      report reportinvocation structureddates vocabulary]

    attr_reader :profile, :name, :label, :id, :config, :ns, :panels,
      :input_tables, :forms, :structured_date_treatment,
      :service_type, :subtypes, :record_search_field, :vocabularies

    def initialize(profileobj, rectypename)
      @profile = profileobj
      @name = rectypename
      @id = "#{@profile.name}/#{@name}"
      @config = @profile.config["recordTypes"][@name]
      @label = config.dig("messages", "record", "name", "defaultMessage")
      @ns = get_namespace
      @panels = get_panels
      @input_tables = get_input_tables
      @forms = get_forms
      @structured_date_treatment = @profile.structured_date_treatment
      @service_type = @config.dig("serviceConfig", "serviceType")
      @subtypes = (@service_type == "authority") ? get_subtypes : []
      @vocabularies = get_vocabularies
    end

    def field_defs
      if @config.dig("fields", "document")
        defs = CCU::Fields::Def::Parser.new(self, @config["fields"]["document"])
        defs.field_defs
      else
        CCU.log.warn("#{profile.name} - #{name} has no field def hash")
      end
    end

    def form_fields = all_form_fields.uniq

    def fields
      fields = form_fields.map { |ff| CCU::Fields::Field.new(self, ff) }
      if @structured_date_treatment == :explode
        fields = explode_structured_date_fields(fields)
      end
      fields = fields.flatten
      fields << media_uri_field if @name == "media"
      fields
    end

    def has_form?(formname) = forms.key?(formname)

    def explode_structured_date_fields(fields)
      sd_fields = fields.select { |f| f.structured_date? }
      fields -= sd_fields
      sd_fields.each do |f|
        fields << CCU::StructuredDateFieldMaker.new(f).fields(@profile)
      end
      fields
    end

    def nonunique_fields
      h = {}
      fields.each do |f|
        path = [f.schema_path, f.name].flatten.join(" > ")
        if h.has_key?(path)
          h[path] << f
        else
          h[path] = [f]
        end
      end
      h.select { |path, farr| farr.length > 1 }
        .keys
    end

    def nonunique_field_names
      h = {}
      fields.each do |f|
        path = [f.schema_path, f.name].flatten.join(" > ")
        if h.has_key?(f.name)
          h[f.name] << path
        else
          h[f.name] = [path]
        end
      end
      h.select { |name, paths| paths.length > 1 }
    end

    def mappings
      checkhash = {}
      mappings = fields.map do |f|
        FieldMapper.new(field: f,
          column_style: profile.column_style).mappings
      end.flatten

      # ensure unique datacolumn values for templates and mapper
      mappings.each do |mapping|
        next if mapping.xpath.nil?

        if checkhash.key?(mapping.datacolumn)
          add = if mapping.xpath.empty?
            mapping.namespace.split("_").last
          else
            mapping.xpath.last
          end
          mapping.datacolumn = "#{add}_#{mapping.datacolumn}"
        else
          checkhash[mapping.datacolumn] = nil
        end
      end
      mappings
    end

    def batch_mappings(context = :mapper)
      mappings = remove_unimportable_fields_from(self.mappings, context)
      mappings = faux_require_mappings(mappings)
      faux_require_profile_specific_mappings(mappings)
    end

    def id_field
      case @service_type
      when "object"
        id_field = "objectNumber"
      when "authority"
        id_field = "shortIdentifier"
      when "procedure"
        required_mappings = batch_mappings.select { |m| m.required == "y" }
        case required_mappings.length
        when 0
          id_field = "potTagNumber" if @name == "pottag"
        when 1
          id_field = required_mappings.first.fieldname
        else
          # osteology has 3 required fields, but only the ID is suitable for use
          # here
          id_field = "InventoryID" if @name == "osteology"
          id_field = "movementReferenceNumber" if @name == "movement"
        end
      end
      id_field
    end

    def search_field
      case @service_type
      when "authority"
        search_path = @config.dig("advancedSearch", "value").first["path"]
        term_group_list = search_path.split("/")[1]
        field = "#{term_group_list}/0/termDisplayName"
      else
        field = id_field
      end
      field
    end

    def unmappable_fields
      unmappable = mappings.select do |mapping|
        mapping.xpath.nil? && mapping.data_type.nil?
      end
      return if unmappable.empty?

      unmappable.each do |mapping|
        puts "#{profile.name} - #{name} - #{mapping.fieldname}"
      end
    end

    def to_s
      "<##{self.class}:#{object_id.to_s(8)} #{profile.name} name: #{name}>"
    end
    alias_method :inspect, :to_s

    private

    # @todo create a public method grouping on id and comparing fields
    #   that appear in multiple forms, to see if any are defined
    #   differently across forms
    def all_form_fields = forms.values.map(&:fields).flatten

    # sets up "faux-required" fields for record types that do not have
    #   any required fields some unique ID field is required for batch
    #   import/processing
    def faux_require_mappings(mappings)
      instructions = {
        "movement" => "movementReferenceNumber",
        "insurance" => "insuranceIndemnityReferenceNumber",
        "transport" => "transportReferenceNumber"
      }
      return mappings unless instructions.key?(@name)

      mapping = get_field_mapping(mappings, instructions[@name])
      mapping.required = "y" unless mapping.nil?
      mappings
    end

    def faux_require_profile_specific_mappings(mappings)
      instructions = {
        "botgarden" => {
          "loanout" => "loanOutNumber",
          "objectexit" => "exitNumber"
        }
      }
      profile = @profile.basename
      return mappings unless instructions.key?(profile)
      return mappings unless instructions[profile].key?(@name)

      mapping = get_field_mapping(mappings, instructions[profile][@name])
      mapping.required = "y" unless mapping.nil?
      mappings
    end

    def get_field_mapping(mappings, fieldname)
      mappings.find { |m| m.fieldname == fieldname }
    end

    def get_vocabularies
      extract_by_key(@config["fields"], "view")
        .select { |h| h["type"] == "TermPickerInput" }
        .select { |h| h.key?("props") }
        .select { |h| h["props"].key?("source") }
        .reject { |h| h["props"]["source"][","] }
        .map { |h| h["props"]["source"] }
        .uniq
        .sort
    end

    # get rid of mappings for fields we do not want to import via the
    # batch import tool
    def remove_unimportable_fields_from(mappings, context)
      constant_instructions = {
        "collectionobject" => %w[computedCurrentLocation]
      }
      mapper_instructions = {
        "media" => %w[mediaFileURI]
      }
      unless constant_instructions.key?(@name) ||
          mapper_instructions.key?(@name)
        return mappings
      end

      if constant_instructions.key?(@name)
        constant_instructions[@name].each do |fieldname|
          mappings = mappings.reject { |m| m.fieldname == fieldname }
        end
      end

      if context == :mapper && mapper_instructions.key?(@name)
        mapper_instructions[@name].each do |fieldname|
          mappings = mappings.reject { |m| m.fieldname == fieldname }
        end
      end

      # omits any fields for which workable mapping cannot be
      # extracted this is introduced in order to output any workable
      # template/mappers for OMCA, because they have custom namespace
      # inside the contact subrecord which the Untangler can't deal
      # with at present
      mappings.reject { |mapping| mapping.data_type.nil? && mapping.xpath.nil? }
    end

    def get_subtypes
      result = []
      vocabs = @config.dig("vocabularies")
      vocabs.each do |keyword, config|
        next if keyword == "all"
        name = config.dig("messages", "name", "defaultMessage")
        servicepath = config.dig("serviceConfig", "servicePath")
        servicepath_name = servicepath.match(/\((.*)\)/)[1]
        result << {name: name, subtype: servicepath_name}
      end
      result
    end

    def media_uri_field
      field_hash = {
        name: "mediaFileURI",
        ns: "not-mapped",
        repeats: "n",
        in_repeating_group: "n/a",
        data_type: "string",
        value_source: [CCU::ValueSources::NoSource.new],
        value_list: [],
        required: "n"
      }
      CCU::Fields::ForcedField.new(self, field_hash)
    end

    def get_forms
      formnames = config.dig("forms").keys
      return {} unless formnames
      return {} if name == "blob"

      # Process the default form first
      formnames.unshift("default") if formnames.include?("default")

      formnames.uniq
        .reject { |fn| fn == "mini" }
        .map { |fn| [fn, CCU::Form.new(self, fn)] }
        .to_h
    end

    def get_input_tables
      if @config.dig("messages", "inputTable")
        h = {}
        @config["messages"]["inputTable"].each do |name, hash|
          h[name] = hash["id"]
          unless @profile.messages.has_key?(hash["id"])
            @profile.messages[hash["id"]] =
              {"name" => hash["defaultMessage"],
               "fullName" => hash["defaultMessage"]}
          end
        end
        h
      else
        {}
      end
    end

    def get_panels
      if @config.dig("messages", "panel")
        arr = []

        @config["messages"]["panel"].keys.each do |panelname|
          arr << panelname

          msgs = @profile.messages
          id = @config["messages"]["panel"][panelname]["id"]
          label = @config["messages"]["panel"][panelname]["defaultMessage"]
          msgs[id] = {"name" => label, "fullName" => label}
        end
        arr
      else
        []
      end
    end

    def get_namespace
      docname = @config["serviceConfig"]["documentName"]
      "ns2:#{docname}_common"
    end
  end
end
