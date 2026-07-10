# frozen_string_literal: true

module CspaceConfigUntangler
  module FieldMap
    # Given a CSpace field, generates one or more FieldMapping objects, each of
    # which corresponds to an incoming data key/column)
    class FieldMapper
      ::FieldMapper = CspaceConfigUntangler::FieldMap::FieldMapper

      # @param field [CCU::Fields::Field]
      # @param column_style %i[fully_consistent consistent data_toolkit fancy]
      def initialize(field:, column_style: :fully_consistent)
        @field = field
        @column_style = column_style
      end

      def sources = @sources ||= derive_sources

      def columns = @columns ||= derive_columns

      def mappings = @mappings ||= create_mappings

      def hash = columns

      def source_type = @source_type ||= get_source_type

      def column_names = sources.map { |src| get_column_name(src) }
        .join("; ")

      private

      attr_reader :field, :column_style

      def derive_sources
        return field.value_sources if column_style == :data_toolkit

        refname_source_added
      end

      def derive_columns
        return derive_data_toolkit_columns if column_style == :data_toolkit

        populate_columns
      end

      def derive_data_toolkit_columns
        return populate_columns unless sources.first.source_type == "authority"

        src = field.value_sources.first
        vocabcol = CCU::ValueSources::DataToolkitAuthVocab.new
        {
          src =>
            data_toolkit_authority_value_column(src),
          vocabcol => data_toolkit_authority_vocab_column
        }
      end

      def data_toolkit_authority_value_column(source)
        base = {
          column_name: field.name,
          source_type: "authority",
          source_name: nil,
          transforms: {}
        }

        append_transforms(base, source)
      end

      def data_toolkit_authority_vocab_column
        {
          column_name: "#{field.name}AuthorityVocabulary",
          source_type: "authority vocabulary indication",
          source_name: nil,
          transforms: {}
        }
      end

      def populate_columns
        sources.map { |source| [source, source_hash(source)] }
          .to_h
      end

      def get_source_type
        return unless sources.respond_to?(:first) &&
          sources.first.respond_to?(:source_type)

        sources.first.source_type
      end

      def source_hash(source)
        base = {
          column_name: get_column_name(source),
          source_type: source.source_type,
          source_name: source.name,
          transforms: {}
        }

        append_transforms(base, source)
      end

      def append_transforms(base, source)
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
        else
          field.name
        end
      end

      def refname_source_added
        srcs = field.value_sources
        src = srcs.first
        return srcs unless needs_refname_source?(src)

        srcs << CCU::ValueSources::Refname.new(src)
        srcs
      end

      # @param sources [#source_type]
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
        columns.map do |source, h|
          if source.source_type == "authority" && !source.configured?
            nil
          else
            FieldMapping.new(field: field,
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
