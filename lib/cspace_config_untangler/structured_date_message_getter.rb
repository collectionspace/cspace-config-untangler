# frozen_string_literal: true

require_relative "messages"

module CspaceConfigUntangler
  class StructuredDateMessageGetter
    # @param config [Hash]
    # @return [CCU::Messages]
    def self.call(config)
      new(config).call
    end

    # @param config [Hash]
    def initialize(config)
      @config = config.transform_values! { |v| v.dig("[config]", "messages") }
      @fields = config.keys
      @messages = CCU::Messages.new
    end

    # @return [CCU::Messages]
    def call
      fields.each { |field| get_field_messages(field) }
      messages
    end

    private

    attr_reader :config, :fields, :messages

    def get_field_messages(field)
      config[field].values.each { |cfg| messages.add(cfg) }
    end

    # def fix_labels(fieldname)
    #   case fieldname
    #   when "dateDisplayDate"
    #     ""
    #   when "datePeriod"
    #     "Period"
    #   when "dateAssociation"
    #     "Association"
    #   when "dateNote"
    #     "Note"
    #   when "dateEarliestSingleDay"
    #     "Earliest/Single day"
    #   when "dateEarliestSingleMonth"
    #     "Earliest/Single month"
    #   when "dateEarliestSingleQualifier"
    #     "Earliest/Single qualifier"
    #   when "dateEarliestSingleQualifierValue"
    #     "Earliest/Single value"
    #   when "dateEarliestSingleYear"
    #     "Earliest/Single year"
    #   when "dateEarliestScalarValue"
    #     "Earliest/Single scalar value"
    #   when "dateLatestDay"
    #     "Latest day"
    #   when "dateLatestMonth"
    #     "Latest month"
    #   when "dateLatestQualifier"
    #     "Latest qualifier"
    #   when "dateLatestQualifierValue"
    #     "Latest value"
    #   when "dateLatestYear"
    #     "Latest year"
    #   when "dateLatestScalarValue"
    #     "Latest scalar value"
    #   when "scalarValuesComputed"
    #     "Scalar values computed?"
    #   end
    # end
  end
end
