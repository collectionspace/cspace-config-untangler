# frozen_string_literal: true

module CspaceConfigUntangler
  module RecordMapper
    class Wrapper
      attr_reader :profile, :rectype, :base_path, :style, :service_type,
        :mappers
      def initialize(profile:, rectype:, base_path:, style: "old")
        @profile = profile
        @rectype = rectype
        @base_path = base_path
        @style = style
        @service_type = rectype.service_type
        @mappers = []
      end

      def call
        if service_type == "authority"
          rectype.subtypes.each do |subtype|
            mappers << get_wrapped_mapper(subtype: subtype)
          end
        else
          mappers << get_wrapped_mapper
        end
        mappers
      end

      private

      def get_wrapped_mapper(subtype: nil)
        if subtype
          {
            mapper: RecordMapping.new(profile: profile, rectype: rectype,
              subtype: subtype, style: style).call,
            path: "#{base_path}/"\
              "#{profile.name}_#{rectype.name}-#{subtype[:name].downcase.tr(
                " ", "-"
              )}.json"
          }
        else
          {
            mapper: RecordMapping.new(profile: profile, rectype: rectype,
              style: style).call,
            path: "#{base_path}/#{profile.name}_#{rectype.name}.json"
          }
        end
      end
    end
  end
end
