# frozen_string_literal: true

module CspaceConfigUntangler
  module FieldMap
    class DataColumnNamerFancy
      ::DataColumnNamerFancy =
        CspaceConfigUntangler::FieldMap::DataColumnNamerFancy

      # @param fieldname [String] base field name from which to generate column
      #   names
      # @param sources [Array<CCU::ValueSources::Authority>] sources for the
      #   columns to be generated
      def initialize(fieldname:, sources:)
        @fieldname = fieldname
        @sources = sources
        # Hash used to check whether to name using authority type, subtype, or
        # both
        @grouped = @sources.reject { |src| src.source_type == "refname" }
          .group_by { |src| src.type }
          .transform_values { |val| val.map(&:subtype) }
      end

      def result
        sources.map { |src| [src, column_name_for(src)] }
          .to_h
      end

      private

      attr_reader :fieldname, :sources, :grouped

      def column_name_for(source)
        return "#{fieldname}Refname" if source.source_type == "refname"

        [fieldname, type(source), subtype(source)].compact
          .join
      end

      def type(source) = append_type? ? source.type.capitalize : nil

      def subtype(source)
        return nil unless append_subtype?(source.type)

        source.subtype.capitalize
      end

      def append_type? = grouped.keys.length > 1

      def append_subtype?(type) = grouped[type].length > 1
    end
  end
end
