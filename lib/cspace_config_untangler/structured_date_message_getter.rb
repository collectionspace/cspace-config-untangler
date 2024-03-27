# frozen_string_literal: true

module CspaceConfigUntangler
  class StructuredDateMessageGetter
    def initialize(profileobj)
      @profile = profileobj
      @config = @profile.config["extensions"]["structuredDate"]["fields"]
      @fields = @config.keys
      set_messages
    end

    private

    def set_messages
      @fields.each { |field|
        id = "field.ext.structuredDate.#{field}"
        name = @config.dig(field, "[config]", "messages", "fullName",
          "defaultMessage")
        fullName = @config.dig(field, "[config]", "messages", "fullName",
          "defaultMessage")
        fullName = fix_labels(field) if fullName.nil?
        @profile.messages[id] = {"name" => name, "fullName" => fullName}
      }
    end

    def fix_labels(fieldname)
      case fieldname
      when "dateDisplayDate"
        ""
      when "datePeriod"
        "Period"
      when "dateAssociation"
        "Association"
      when "dateNote"
        "Note"
      when "dateEarliestSingleDay"
        "Earliest/Single day"
      when "dateEarliestSingleMonth"
        "Earliest/Single month"
      when "dateEarliestSingleQualifier"
        "Earliest/Single qualifier"
      when "dateEarliestSingleQualifierValue"
        "Earliest/Single value"
      when "dateEarliestSingleYear"
        "Earliest/Single year"
      when "dateEarliestScalarValue"
        "Earliest/Single scalar value"
      when "dateLatestDay"
        "Latest day"
      when "dateLatestMonth"
        "Latest month"
      when "dateLatestQualifier"
        "Latest qualifier"
      when "dateLatestQualifierValue"
        "Latest value"
      when "dateLatestYear"
        "Latest year"
      when "dateLatestScalarValue"
        "Latest scalar value"
      when "scalarValuesComputed"
        "Scalar values computed?"
      end
    end
  end # class
end # module
