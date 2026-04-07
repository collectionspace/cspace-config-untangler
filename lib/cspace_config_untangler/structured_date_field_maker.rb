# frozen_string_literal: true

module CspaceConfigUntangler
  class StructuredDateFieldMaker
    attr_reader :parent, :profile, :rectype, :ns, :ns_for_id, :panel, :ui_path,
      :schema_path,
      :repeats, :in_repeating_group,
      :required

    # @param field_obj [CCU::Fields::Field]
    # @param sd_config [Hash] extensions/structuredDate/fields from profile
    def initialize(field_obj, sd_config)
      @parent = field_obj
      @config = sd_config
      @profile = @parent.profile
      @rectype = @parent.rectype
      @ns = @parent.ns
      @ns_for_id = "ext.structuredDate"
      @panel = @parent.panel
      @ui_path = @parent.ui_path << @parent.messages.first
      @schema_path = @parent.schema_path << @parent.name
      @repeats = "n"
      @in_repeating_group = set_group_repeats
      @required = "n"
    end

    def fields
      config.map do |field, cfg|
        CCU::StructuredDateField.new(field, cfg, self)
      end
    end

    private

    attr_reader :config

    def set_group_repeats
      if @parent.repeats == "y"
        "y"
      elsif @parent.in_repeating_group == "y"
        "as part of larger repeating group"
      elsif @parent.in_repeating_group == "n/a"
        "n"
      end
    end
  end
end
