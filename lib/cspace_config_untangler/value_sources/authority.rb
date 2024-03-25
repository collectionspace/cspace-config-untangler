# frozen_string_literal: true

module CspaceConfigUntangler
  module ValueSources
    # basic value object to represent an authority
    class Authority < AbstractValueSource
      def initialize(authority_source_string, profile)
        @name = authority_source_string
        split = name.split("/")
        @type = split[0]
        @subtype = split[1]
        @source_type = "authority"
        @config = profile.config.dig("recordTypes", type)
      end

      def column_header_consistent(fieldname)
        "#{fieldname}#{type.capitalize}#{subtype.capitalize}"
      end

      def column_header_fancy(fieldname, sources)
        all = CCU::FieldMap::DataColumnNamerFancy.new(
          fieldname: fieldname, sources: sources
        )
        all.result[self]
      end

      def configured?
        service_paths.length == 2
      end

      def service_paths
        return [] unless @config

        [type_service_path, subtype_service_path].compact
      end

      def transforms
        {authority: service_paths}
      end

      private

      def type_service_path
        path = @config.dig("serviceConfig", "servicePath")
        return unless path

        path
      end

      def subtype_service_path
        subtype_config = @config.dig("vocabularies", subtype)
        return unless subtype_config

        path = subtype_config.dig("serviceConfig", "servicePath")
        return unless path

        path.match(/\((.*)\)$/)[1]
      end
    end
  end
end
