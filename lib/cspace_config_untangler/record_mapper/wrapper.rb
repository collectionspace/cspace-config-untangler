module CspaceConfigUntangler
  module RecordMapper
    class Wrapper
      attr_reader :mappers
      def initialize(profile:, rectype:, base_path:)
        @profile = profile
        @rectype = rectype
        @base_path = base_path
        @service_type = @rectype.service_type
        @mappers = []

        if @service_type == 'authority'
          @rectype.subtypes.each do |subtype|
            @mappers << get_wrapped_mapper(subtype: subtype)
          end
        else
          @mappers << get_wrapped_mapper
        end
      end

      private

      def get_wrapped_mapper(subtype: nil)
        if subtype
          {
            mapper: RecordMapping.new(profile: @profile, rectype: @rectype, subtype: subtype),
            path: "#{@base_path}/#{@profile.name}_#{@rectype.name}-#{subtype[:name].downcase.gsub(' ', '-')}.json"
          }
        else
          {
            mapper: RecordMapping.new(profile: @profile, rectype: @rectype),
            path: "#{@base_path}/#{@profile.name}_#{@rectype.name}.json"
          }
        end
      end
    end
  end
end
