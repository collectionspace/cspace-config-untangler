# frozen_string_literal: true

module CspaceConfigUntangler
  module Forms
    # Props from a subrecord's form config
    class Subrecord < Props
      FORM_LOOKUP = {
        "contact" => "default",
        "blob" => "view"
      }

      # @param name ["blob", "contact"]
      # @param form [CCU::Forms::Form]
      # @param validator [CCU::Forms::PropsValidator]
      # @param parent [nil, CCU::Forms::Props]
      def initialize(name, form, validator, parent = nil)
        @subrecname = name
        @validator = validator
        @subrec = form.profile.config.dig("recordTypes", name)
        @subrecform = subrec.dig("forms", FORM_LOOKUP[name])
        @config = subrecform.dig("template", "props", "children", "props")

        super(form, validator, @config, parent)
      end

      def extension? = true

      def ns
        subrec.dig("fields", "document", "[config]", "view", "props",
          "defaultChildSubpath")
      end

      def panel
        subrec.dig("messages", "panel", config["name"], "id")
      end

      def panel? = true

      private

      attr_reader :subrecname, :subrec, :subrecform
    end
  end
end
