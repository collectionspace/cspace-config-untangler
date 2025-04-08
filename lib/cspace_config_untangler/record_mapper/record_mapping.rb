# frozen_string_literal: true

module CspaceConfigUntangler
  module RecordMapper
    class RecordMapping
      ::RecordMapping = CspaceConfigUntangler::RecordMapper::RecordMapping
      include JsonWritable
      attr_reader :hash, :mappings

      # profile = CCU::Profile
      # rectype = CCU::RecordType
      def initialize(profile:, rectype:, subtype: nil)
        @profile = profile
        @rectype = rectype
        @subtype = subtype
        @mappings = @rectype.batch_mappings
        @config = @profile.config
        @hash = {}
        build_hash
        append_subtype if @subtype
      end

      private

      def append_subtype
        @hash[:config][:authority_type] = @hash[:config][:service_path]
        @hash[:config][:authority_subtype] = @subtype[:subtype]
      end

      def build_hash
        @hash[:config] = {}
        @hash[:config][:dataConfigType] = "record type"
        @hash[:config][:profile_basename] = @profile.basename
        @hash[:config][:version] = @profile.readable_version
        @hash[:config][:recordtype] = @rectype.name
        @hash[:config][:document_name] =
          @config.dig("recordTypes", @rectype.name, "serviceConfig",
            "documentName")
        @hash[:config][:service_name] =
          @config.dig("recordTypes", @rectype.name, "serviceConfig",
            "serviceName")
        @hash[:config][:service_path] =
          @config.dig("recordTypes", @rectype.name, "serviceConfig",
            "servicePath")
        @hash[:config][:service_type] = @rectype.service_type
        @hash[:config][:object_name] =
          @config.dig("recordTypes", @rectype.name, "serviceConfig",
            "objectName")
        @hash[:config][:ns_uri] = NamespaceUris.new(profile_config: @config,
          rectype: @rectype.name,
          mapper_config: @hash[:config]).hash
        @hash[:config][:identifier_field] = @rectype.id_field
        @hash[:config][:search_field] = @rectype.search_field
        if @rectype.service_type == "authority"
          @hash[:config][:authority_subtypes] =
            @rectype.subtypes
        end
        @hash[:docstructure] = {}
        create_hierarchy
        @hash[:mappings] = @mappings.map { |m| m.to_h }
      end

      def create_hierarchy
        # top level keys are the namespaces
        @mappings.each do |m|
          @hash[:docstructure][m.namespace] = {}
        end

        @mappings.each do |m|
          next if m.data_type.nil? && m.xpath.nil?

          levels = m.xpath.clone
          done = []
          while levels.size > 0
            thislevel = levels.shift
            path = done.clone << thislevel
            add_key = if @hash[:docstructure][m.namespace].dig(*path)
              false
            else
              true
            end
            if add_key
              add_path = if done.empty?
                @hash[:docstructure][m.namespace]
              else
                @hash[:docstructure][m.namespace].dig(*done)
              end
              add_path[thislevel] = {}
            end
            done << thislevel
          end
        end
      end
    end
  end
end
