# frozen_string_literal: true

require_relative "column_name_stylable"
require_relative "record_type"

module CspaceConfigUntangler
  class Profile
    include CCU::ColumnNameStylable
    attr_reader :name, :config, :authorities, :rectypes, :rectypes_all,
      :extensions, :vocabularies, :panels, :form_fields, :field_defs, :messages, :structured_date_treatment

    def initialize(profile:, rectypes: [], structured_date_treatment: :explode)
      @name = profile
      @config = JSON.parse(File.read("#{CCU.configdir}/#{@name}.json"))
      @messages = {}
      @extensions = get_extensions
      @structured_date_treatment = structured_date_treatment
      @rectypes_all = get_rectypes_all
      @rectypes = get_rectypes(rectypes)
      @authorities = get_authorities
      @vocabularies = get_vocabularies
      @panels = get_panels
      CCU::StructuredDateMessageGetter.new(self) if @structured_date_treatment == :explode
      get_field_defs
      apply_overrides
      get_form_fields
    end

    def column_style
      column_name_style(basename, version)
    end

    def extensions_for(rectype)
      exts = {}
      @extensions.map { |e| CCU::Extension.new(self, e) }.each do |ext|
        if ext.type == "generic"
          exts[ext.name] = ext
        elsif ext.rectypes.include?(rectype)
          exts[ext.name] = ext
        end
      end
      exts
    end

    def defined_fields_not_used
      form_field_lookup = form_fields_by_id
      arr = []
      field_defs.keys.each do |fd|
        arr << fd unless form_field_lookup.has_key?(fd)
      end
      arr
    end

    def fields
      @rectypes.map { |rt| rt.fields }.flatten
    end

    def nonunique_fields
      @rectypes.map { |rt| [rt.name, rt.nonunique_fields] }
        .to_h
        .reject { |rt, info| info.empty? }
    end

    def nonunique_field_names
      @rectypes.map { |rt| [rt.name, rt.nonunique_field_names] }
        .to_h
        .reject { |rt, info| info.empty? }
    end

    def basename
      @name.split("_")[0]
    end

    def version
      @name.split("_")[1]
    end

    def special_rectypes
      arr = []
      rtnames = @rectypes.map(&:name)
      arr << CCU::ObjectHierarchy.new(profile: self) if rtnames.include?("collectionobject")
      arr << CCU::AuthorityHierarchy.new(profile: self) if rectypes_include_authorities
      if rtnames.include?("collectionobject") || rectypes_include_procedures
        arr << CCU::NonHierarchicalRelationship.new(profile: self)
      end
      arr
    end

    def authority_types
      @rectypes_all.select do |rt|
        @config["recordTypes"][rt]["serviceConfig"]["serviceType"] == "authority"
      end
        .map { |rt| @config["recordTypes"][rt]["serviceConfig"]["servicePath"] }
        .sort
    end

    def authority_subtypes
      ast = @rectypes_all.select do |rt|
              @config["recordTypes"][rt]["serviceConfig"]["serviceType"] == "authority"
            end
        .map { |rt| @config["recordTypes"][rt]["vocabularies"] }
        .map do |vocabhash|
              vocabhash.map do |vocab, h|
                h["serviceConfig"]["servicePath"]
              end
            end
        .flatten
        .reject { |e| e == "_ALL_" }
        .map { |refname| refname.match(/\((.*)\)/)[1] }
        .uniq
      ast.sort
    end

    def object_and_procedures
      op = @rectypes_all.select do |rt|
             @config["recordTypes"][rt]["serviceConfig"]["serviceType"] == "procedure"
           end
        .map { |rt| @config["recordTypes"][rt]["serviceConfig"]["servicePath"] }
      op << "collectionobjects"
      op.sort
    end

    def option_lists
      @option_lists ||= get_option_lists
    end

    # @return Array of authority vocabulary names used to control at least one
    #   field in profile
    def used_authority_vocabs
      field_defs.values
        .flatten
        .map { |fd| fd.value_source }
        .flatten
        .select { |src| src.is_a?(CCU::ValueSources::Authority) }
        .map(&:name)
        .uniq
        .sort
    end

    # @return Array of authority vocabulary names defined but not used to
    #   control any fields
    def unused_authority_vocabs
      authorities - used_authority_vocabs
    end

    def inspect
      %(#<#{self.class}:#{object_id} name: #{@name}>)
    end

    private

    def get_field_defs
      fields = @rectypes.map { |rt| rt.field_defs }
      if @extensions.include?("blob")
        fields << CCU::RecordType.new(self,
          "blob").field_defs
      end

      h = {}
      fields.flatten.each do |f|
        if h.has_key?(f.id)
          h[f.id] << f
        else
          h[f.id] = [f]
        end
      end

      @field_defs = h
    end

    def get_form_fields
      fields = @rectypes.map { |rt| rt.form_fields }
      @form_fields = fields.flatten
    end

    def form_fields_by_id
      h = {}
      @form_fields.each { |ff| h[ff.id] = ff }
      h
    end

    def get_panels
      panels = @rectypes.map { |rt| rt.panels }
      if @extensions.include?("contact")
        panels << CCU::RecordType.new(self,
          "contact").panels
      end
      panels.flatten.sort
    end

    def get_vocabularies
      @rectypes.map(&:vocabularies).flatten.uniq.sort
    end

    def apply_overrides
      # This applies messages defined at the profile level
      o = @config.dig("messages")
      o&.each do |k, v|
        apply_field_override(k, v) if k.start_with?("field.")
        apply_panel_override(k, v) if k.start_with?("panel.")
      end

      # This accounts for the fact that the livingplant extension ids don't use extension format
      #  in field definitions
      to_update = @messages.keys.select do |e|
        e["field.conservation_livingplant"]
      end
      to_update.each do |key|
        newkey = key.sub("field.conservation_livingplant",
          "field.ext.livingplant")
        @messages[newkey] = @messages[key]
        @messages.delete(key)
      end
    end

    def apply_field_override(id, value)
      type = id.split(".").last
      rev_id = id.sub(".#{type}", "")

      if @messages.has_key?(rev_id)
        @messages[rev_id][type] = value
      else
        @messages[rev_id] = {type => value}
      end
    end

    def apply_panel_override(id, value)
      @messages[id] = {"name" => value, "fullName" => value}
    end

    def get_rectypes_all
      config["recordTypes"].keys - CCU::RecordType::IGNORED
    end

    def get_rectypes(rectypes)
      types = if rectypes.empty?
        rectypes_all
      else
        rectypes_all.intersection(rectypes)
      end

      types.map { |rt| CCU::RecordType.new(self, rt) }
    end

    def get_extensions
      remove = %w[core authItem]
      ext = @config["extensions"].keys - remove
      %w[contact blob].each do |subrec|
        ext << subrec if @config["recordTypes"].key?(subrec)
      end
      ext
    end

    def get_authorities
      authorities = []
      @rectypes_all.each do |rt|
        c = @config["recordTypes"][rt]
        if c.dig("serviceConfig", "serviceType") == "authority"
          c["vocabularies"].keys.reject { |e| e == "all" }.each do |subtype|
            authorities << "#{rt}/#{subtype}"
          end
        else
          next
        end
      end
      authorities.sort
    end

    def rectypes_include_authorities
      !@rectypes.select do |rt|
        rt.service_type == "authority"
      end.empty?
    end

    def rectypes_include_procedures
      !@rectypes.select do |rt|
        rt.service_type == "procedure"
      end.empty?
    end

    def get_option_lists
      list_config = @config.dig("optionLists")
      return [] unless list_config

      CCU::OptionLists.new(@config["optionLists"])
    end
  end
end
