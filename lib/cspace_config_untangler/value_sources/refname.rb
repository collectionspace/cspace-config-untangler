# frozen_string_literal: true

module CspaceConfigUntangler
  module ValueSources
    # Authority or Vocabulary Refname source
    class Refname < AbstractValueSource
      # @param source [CCU::ValueSources::Authority,
      #   CCU::ValueSources::Vocabulary]
      def initialize(source)
        @type = source.source_type
        @source_type = "refname"
        @name = "#{type} #{source_type}"
        @subtype = nil
      end

      def column_header_consistent(fieldname) = "#{fieldname}Refname"

      def column_header_fancy(fieldname, sources) = "#{fieldname}Refname"
    end
  end
end
