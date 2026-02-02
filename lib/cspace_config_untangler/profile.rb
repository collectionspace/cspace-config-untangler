# frozen_string_literal: true

require_relative "column_name_stylable"
require_relative "messageable"
require_relative "record_type"

module CspaceConfigUntangler
  class Profile
    include CCU::ColumnNameStylable
    include Messageable

    # @return [String] name of the profile
    attr_reader :name

    # @return [:collapsed, :expanded]
    attr_reader :structured_date_treatment

    # @return [Hash] derived from JSON config for the profile
    attr_reader :config

    # @param profile [String] profile name; must match a file in `data/configs`
    #   directory, minus `.json` file extension
    # @param rectypes [Array<String>] rectype names to include in processing
    # @param structured_date_treatment [:collapsed, :expanded]
    def initialize(profile:, rectypes: [], structured_date_treatment: :expanded)
      @name = profile
      @structured_date_treatment = structured_date_treatment
      @config = JSON.parse(File.read("#{CCU.configdir}/#{@name}.json"))
      @rectype_names = rectypes.empty? ? rectypes_all : rectypes
      message_setup
    end

    # @return [Array<CCU::RecordType>] selected/specified for processing
    def rectypes = @rectypes ||= get_rectypes

    # @return [Array<String>] shortIdentifier values of all vocabularies defined
    #   as term sources for fields used in profile
    def vocabularies = @vocabularies ||= get_vocabularies

    def panels = @panels ||= get_panels

    # @return [Array<String>] names of extensions defined in the profile
    def extensions = @extensions ||= get_extensions

    def authorities = @authorities ||= get_authorities

    def field_defs = @field_defs ||= get_field_defs

    def form_fields = @form_fields ||= get_form_fields

    def column_style
      column_name_style(basename, version)
    end

    def extensions_for(rectype)
      exts = {}
      extensions.map { |e| CCU::Extension.new(self, e) }.each do |ext|
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
      rectypes.map { |rt| rt.fields }.flatten
    end

    def nonunique_fields
      rectypes.map { |rt| [rt.name, rt.nonunique_fields] }
        .to_h
        .reject { |rt, info| info.empty? }
    end

    def nonunique_field_names
      rectypes.map { |rt| [rt.name, rt.nonunique_field_names] }
        .to_h
        .reject { |rt, info| info.empty? }
    end

    def basename
      @name.split("_")[0]
    end

    # return [String] version suitable for writing to file/directory paths
    def version = @name.split("_")[1]

    def readable_version = version.tr("-", ".")

    def special_rectypes
      arr = []
      if rectype_names.include?("collectionobject")
        arr << CCU::ObjectHierarchy.new(profile: self)
      end
      if rectypes_include_authorities
        arr << CCU::AuthorityHierarchy.new(profile: self)
      end
      if rectype_names.include?("collectionobject") ||
          rectypes_include_procedures
        arr << CCU::NonHierarchicalRelationship.new(profile: self)
      end
      arr
    end

    def authority_types
      rectypes_all.select do |rt|
        @config.dig(
          "recordTypes", rt, "serviceConfig", "serviceType"
        ) == "authority"
      end
        .map { |rt| @config["recordTypes"][rt]["serviceConfig"]["servicePath"] }
        .sort
    end

    def authority_subtypes
      ast = rectypes_all.select do |rt|
        @config.dig(
          "recordTypes", rt, "serviceConfig", "serviceType"
        ) == "authority"
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
      op = rectypes_all.select do |rt|
        @config.dig(
          "recordTypes", rt, "serviceConfig", "serviceType"
        ) == "procedure"
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
        .map { |fd| fd.value_sources }
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

    # @return [Hash] where keys are element ids and values are defaultMessages
    #   for those ids
    def message_overrides = config.dig("messages")

    private

    attr_reader :rectype_names

    def extract_messages
      rectypes.each { |rt| add_messages(rt.messages) }

      if structured_date_treatment == :expanded
        sdconfig = config.dig("extensions", "structuredDate", "fields")
        add_messages(CCU::StructuredDateMessageGetter.call(sdconfig))
      end
    end

    # def apply_overrides
    #   # This applies messages defined at the profile level
    #   return unless message_overrides

    #   message_overrides.each do |k, v|
    #     cfg = {"id" => k, "defaultMessage" => v}
    #     @messages.override(cfg)
    #   end
    # end

    def service_groups
      @service_groups ||= CCU::Profiles::ServiceGroupsGetter.call(basename)
    end

    def get_field_defs
      fields = rectypes.map { |rt| rt.field_defs }
      if extensions.include?("blob")
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

      h
    end

    def get_form_fields = rectypes.map(&:form_fields).flatten

    def form_fields_by_id
      h = {}
      form_fields.each { |ff| h[ff.id] = ff }
      h
    end

    def get_panels
      panels = rectypes.map { |rt| rt.panels }
      if extensions.include?("contact")
        panels << CCU::RecordType.new(self,
          "contact").panels
      end
      panels.flatten.sort
    end

    def get_vocabularies
      rectypes.map(&:vocabularies).flatten.uniq.sort
    end

    def rectypes_all
      @ui_config_rectype_names ||= config["recordTypes"].keys -
        CCU::RecordType::IGNORED
    end

    def get_rectypes
      types = if rectype_names.empty?
        rectypes_all
      else
        rectypes_all.intersection(rectype_names)
      end

      rt_objs = types.map { |rt| CCU::RecordType.new(self, rt) }
      if service_groups.empty?
        CCU.log.warn("No API client for #{name} configured. Disabled/"\
                     "suppressed record types not marked as such in UI config "\
                     "cannot be excluded by checking against services "\
                     "\\servicegroups DocTypes.")
        return rt_objs
      end

      rt_objs.select { |rt| service_groups.include?(rt.object_name) }
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
      rectypes_all.each do |rt|
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
      !rectypes.select do |rt|
        rt.service_type == "authority"
      end.empty?
    end

    def rectypes_include_procedures
      !rectypes.select do |rt|
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
