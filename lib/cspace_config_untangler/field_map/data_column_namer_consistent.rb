# frozen_string_literal: true

module CspaceConfigUntangler
  module FieldMap
    class DataColumnNamerConsistent
      ::DataColumnNamerConsistent = CspaceConfigUntangler::FieldMap::DataColumnNamerConsistent
      attr_reader :result
      # @param fieldname [String] base field name from which to generate column names
      # @param sources [Array<CCU::ValueSources::Authority>] sources for the columns to be generated
      def initialize(fieldname:, sources:)
        @fieldname = fieldname
        @sources = sources
        @result = {}
        @sources.each do |source|
          name = "#{@fieldname}#{source.type.capitalize}#{source.subtype.capitalize}"
          @result[source] = name
        end
      end
    end
  end
end
