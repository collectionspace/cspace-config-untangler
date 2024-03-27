# frozen_string_literal: true

module CspaceConfigUntangler
  module FieldMap
    # Given a CSpace field, generates one or more FieldMapping objects, each of
    # which corresponds to an incoming data key/column)
    class FieldMapper
      ::FieldMapper = CspaceConfigUntangler::FieldMap::FieldMapper
      attr_reader :mappings, :source_type
      def initialize(field:, column_style: :fully_consistent)
        @field = field
        @sources = field.value_source
        @column_style = column_style
        @source_type = sources.first.source_type
        add_refname_source
        @fieldhash = populate_hash
        # @hash = structure_hash
        # get_data_columns
        # get_source_types
        # get_transforms
        @mappings = create_mappings
      end

      def hash = fieldhash

      private

      attr_reader :field, :sources, :column_style, :fieldhash

      def populate_hash
        sources.map { |source| populate_source(source) }
          .to_h
      end

      def populate_source(source)
        [source, source_hash(source)]
      end

      def source_hash(source)
        base = {
          column_name: get_column_name(source),
          source_type: source.source_type,
          source_name: source.name,
          transforms: {}
        }
        return base if source.source_type == "refname"
        base[:transforms].merge!(transforms) if transforms
        base[:transforms].merge!(source.transforms) if source.transforms
        base
      end

      def get_column_name(source)
        case column_style
        when :fully_consistent
          source.column_header_consistent(field.name)
        when :consistent
          if sources.count { |src| !(src.source_type == "refname") } == 1
            case source.source_type
            when "refname"
              source.column_header_consistent(field.name)
            else
              field.name
            end
          else
            source.column_header_consistent(field.name)
          end
        when :fancy
          source.column_header_fancy(field.name, sources)
        end
      end

      def add_refname_source
        src = sources.first
        return unless needs_refname_source?(src)

        @sources << CCU::ValueSources::Refname.new(src)
      end

      # @param source [#source_type]
      def needs_refname_source?(source)
        %w[authority vocabulary].include?(source.source_type)
      end

      def transforms
        special = []
        if field.name.downcase["behrensmeyer"]
          special << "behrensmeyer_translate"
        end
        special << "boolean" if field.data_type == "boolean"

        special.empty? ? nil : {special: special}
      end

      def create_mappings
        fieldhash.map do |source, h|
          if source.source_type == "authority" && !source.configured?
            nil
          else
            FieldMapping.new(field: @field,
              datacolumn: h[:column_name],
              transforms: h[:transforms],
              source_type: h[:source_type],
              source_name: h[:source_name])
          end
        end.compact
      end
    end
  end
end
