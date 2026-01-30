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
        @subrecname = (name == "contact") ? name : "blob"
        @subrec = form.profile.config.dig("recordTypes", subrecname)
        @subrecform = subrec.dig("forms", FORM_LOOKUP[subrecname])
        @config = subrecform.dig("template", "props", "children", "props")

        super(form, validator, @config, parent)

        @is_panel = true
      end

      def extension? = true

      def ns
        subrec.dig("fields", "document", "[config]", "view", "props",
          "defaultChildSubpath")
      end

      def panel
        subrec.dig("messages", "panel", config["name"], "id")
      end

      def extract_messages
        form.add_messages(subrec["messages"]) if subrec.key?("messages")
        form.add_messages(subrecform["messages"]) if subrecform.key?("messages")
      end

      private

      attr_reader :subrecname, :subrec, :subrecform
    end
  end
end
