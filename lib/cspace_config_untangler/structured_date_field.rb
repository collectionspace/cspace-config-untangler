# frozen_string_literal: true

require_relative "fields/field"

module CspaceConfigUntangler
  class StructuredDateField < CCU::Fields::Field
    DATA_TYPES = {
      "dateDisplayDate" => "string",
      "dateAssociation" => "string",
      "datePeriod" => "string",
      "dateNote" => "string",
      "dateEarliestSingleCertainty" => "string",
      "dateEarliestSingleDay" => "integer",
      "dateEarliestSingleEra" => "string",
      "dateEarliestSingleMonth" => "integer",
      "dateEarliestSingleQualifier" => "string",
      "dateEarliestSingleQualifierUnit" => "string",
      "dateEarliestSingleQualifierValue" => "integer",
      "dateEarliestSingleYear" => "integer",
      "dateLatestCertainty" => "string",
      "dateLatestDay" => "integer",
      "dateLatestEra" => "string",
      "dateLatestMonth" => "integer",
      "dateLatestQualifier" => "string",
      "dateLatestQualifierUnit" => "string",
      "dateLatestQualifierValue" => "integer",
      "dateLatestYear" => "integer",
      "dateEarliestScalarValue" => "string",
      "dateLatestScalarValue" => "string",
      "scalarValuesComputed" => "boolean"
    }

    attr_reader :profile, :rectype, :name, :parent, :ns, :ns_for_id, :panel,
      :ui_path, :id, :fid, :schema_path, :repeats, :in_repeating_group,
      :required

    # def initialize(profile_obj, structured_date_field_maker, field_id)
    def initialize(fieldname, config, maker)
      @name = fieldname
      @config = config.dig("[config]")
      @parent = maker
      @profile = maker.profile
      message_setup
      @rectype = maker.rectype
      @ns = maker.ns
      @ns_for_id = maker.ns_for_id
      @panel = maker.panel
      @ui_path = maker.ui_path
      @id = "ext.structuredDate.#{name}"
      @fid = "#{@profile.name} #{rectype.name} #{parent.parent.name} "\
        "#{ns_for_id} #{@name}"
      @schema_path = maker.schema_path
      @repeats = maker.repeats
      @in_repeating_group = maker.in_repeating_group
      @required = maker.required
    end

    def data_type = DATA_TYPES[name]

    def value_sources
      return unless value_type

      src = CCU::Fields::ValueSources::SourceExtractor.call(
        value_type, config, profile
      )

      if src.empty? && value_type == "authority"
        CCU.log.warn(
          "DATA SOURCES: #{config.namespace_signature} - #{id} - "\
            "Autocomplete defined with no source"
        )
        return
      end

      src
    end

    def value_list
      return unless value_type == "option list"

      value_sources.first.options
    end

    def extract_messages
      return unless config&.key?("messages")

      add_messages(config["messages"])
    end

    private

    attr_reader :config

    def value_type
      @value_type ||= CCU::Fields::ValueSources::TypeExtractor.call(config)
    end
  end # class Field
end # module
