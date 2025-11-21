# frozen_string_literal: true

require_relative "fields/definition/parser"
require_relative "iterable"
require_relative "record_types/service_config"
require_relative "ucbable"

module CspaceConfigUntangler
  class RecordType
    include CCU::Iterable
    include Ucbable

    # Names of record types we don't interact with as first-class data-layer
    # entities, which are thus ignored by this application.
    #
    # NOTE: we pull blob and contact in as subrecords where they are
    # included as such, but we don't treat them as a record type that
    # you can ingest on their own
    #
    # NOTE: object is the superclass of collectionobject and any other "object"
    # record types that may be added in the future, like procedure is the
    # superclass of all record types listed under procedures on the Create New
    # page
    IGNORED = %w[account all audit authrole authority batch batchinvocation
      blob contact export idgenerator object procedure relation
      report reportinvocation structureddates vocabulary]

    attr_reader :profile, :name, :id, :config, :ns,
      :input_tables, :structured_date_treatment,
      :service_type, :subtypes, :record_search_field

    # @return [Array<String>] shortIdentifier values of all vocabularies defined
    #   as term sources for fields used in record type
    attr_reader :vocabularies

    def initialize(profileobj, rectypename)
      @profile = profileobj
      @name = rectypename
      @id = "#{@profile.name}/#{@name}"
      @config = @profile.config["recordTypes"][@name]

      @ns = get_namespace
      @messages = CCU::Messages.new
      @input_tables = get_input_tables
      @structured_date_treatment = @profile.structured_date_treatment
      @service_type = service_config.service_type
      @subtypes = (@service_type == "authority") ? get_subtypes : []
      @vocabularies = get_vocabularies
      @messages_extracted = false
    end

    # @param msgs [CCU::Messages]
    def add_messages(msgs) = @messages.add(msgs)

    # @return [Array<CCU::Forms::Form>]
    def forms = @forms ||= get_forms

    # @return [Array<String>]
    def panels = @panels ||= get_panels

    def messages
      extract_messages unless messages_extracted

      @messages
    end

    def label
      @label ||= config.dig("messages", "record", "name", "defaultMessage")
    end

    def object_name
      service_config.object_name
    end

    def field_defs = @field_defs ||= get_field_defs

    def form_fields = @form_fields ||= all_form_fields.uniq

    def fields = @fields ||= get_fields

    def media? = %w[media restrictedmedia].include?(name)

    def has_form?(formname) = forms.any? { |f| f.name == formname }

    def explode_structured_date_fields(fields)
      sd_fields = fields.select { |f| f.structured_date? }
      fields -= sd_fields
      sd_fields.each do |f|
        fields << CCU::StructuredDateFieldMaker.new(f).fields(@profile)
      end
      fields
    end

    def mappings = @mappings ||= derive_mappings

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

    def derive_mappings
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
      importable = remove_unimportable_fields_from(mappings, context)
      faux_require_profile_specific_mappings(faux_require_mappings(importable))
    end

    def id_field
      case @service_type
      when "object"
        "objectNumber"
      when "authority"
        "shortIdentifier"
      when "procedure"
        required_mappings = batch_mappings.select { |m| m.required == "y" }
        case required_mappings.length
        when 0
          case name
          when "loanout" then "loanOutNumber"
          when "pottag" then "potTagNumber"
          end
        when 1
          required_mappings.first.fieldname
        else
          case name
          when "movement" then "movementReferenceNumber"
            # osteology has 3 required fields, but only the ID is
            # suitable for use here
          when "osteology" then "InventoryID"
          end
        end
      end
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

    attr_reader :messages_extracted

    def extract_messages
      forms.each { |form| form.messages }
      field_defs
    end

    def get_field_defs
      if @config.dig("fields", "document")
        CCU::Fields::Def::Parser.call(self, @config["fields"]["document"])
      else
        CCU.log.warn("#{profile.name} - #{name} has no field def hash")
      end
    end

    def get_fields
      fields = form_fields.map { |ff| CCU::Fields::Field.new(self, ff) }
        .select { |field| field.ok? }
      if @structured_date_treatment == :explode
        fields = explode_structured_date_fields(fields)
      end
      fields = fields.flatten
      fields << media_uri_field if media?
      fields
    end

    def service_config
      @service_config ||= CCU::RecordTypes::ServiceConfig.new(
        @config.dig("serviceConfig")
      )
    end

    # @todo create a public method grouping on id and comparing fields
    #   that appear in multiple forms, to see if any are defined
    #   differently across forms
    def all_form_fields = forms.select(&:enabled?)
      .map { |f| f.fields }
      .flatten

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
        .map { |fn| CCU::Form.new(self, fn) }
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
      return "ns2:contacts_common" if name == "contact"

      value_idx = if second_adv_search_ns?
        1
      elsif third_adv_search_ns?
        2
      else
        0
      end
      config.dig("advancedSearch", "value", value_idx, "path")&.split("/")
        &.first
    end

    def second_adv_search_ns?
      profile.basename == "botgarden" && name == "loanout" ||
        ucb_second_adv_search_ns?(self)
    end

    def third_adv_search_ns?
      ucb_third_adv_search_ns?(self)
    end
  end
end
