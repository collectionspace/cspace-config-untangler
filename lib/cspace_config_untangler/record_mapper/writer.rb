# frozen_string_literal: true

module CspaceConfigUntangler
  module RecordMapper
    # Used by the CLI `mappers write` to orchestrate writing of
    #   mappers to the specified destination. Handles the
    #   writing of a separate wrapper per authority subtype.
    class Writer
      attr_reader :profile, :rectype, :base_path, :style, :service_type
      def initialize(profile:, rectype:, base_path:, style: "old")
        @profile = profile
        @rectype = rectype
        @base_path = base_path
        @style = style
        @service_type = rectype.service_type
      end

      def write = mappers.each { |mapper| mapper.write }

      # @return [Array<CCU::RecordMapper::RecordMapping>]
      def mappers
        return [get_wrapped_mapper] unless service_type == "authority"

        rectype.subtypes.map do |subtype|
          get_wrapped_mapper(subtype: subtype)
        end
      end

      private

      def get_wrapped_mapper(subtype: nil)
        RecordMapping.new(profile: profile, rectype: rectype,
          subtype: subtype, style: style,
          path: mapper_path(subtype))
      end

      def mapper_path(subtype)
        base_name = "#{profile.name}_#{rectype.name}"
        return File.join(base_path, "#{base_name}.json") unless subtype

        subtype_for_path = subtype[:name].downcase
          .tr(" ", "-")
        File.join(base_path, "#{base_name}-#{subtype_for_path}.json")
      end
    end
  end
end
