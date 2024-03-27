require_relative "properties"

module CspaceConfigUntangler
  module Forms
    class Form
      ::CCU::Form = CspaceConfigUntangler::Forms::Form
      attr_reader :rectype, :name, :config, :fields

      def initialize(rectypeobj, formname)
        @rectype = rectypeobj
        @name = formname
        @config = rectype.config["forms"][name]["template"]["props"]
        @fields = []
        return self if disabled?

        get_form_fields

        # This logic loop prevents failure for of publicart work due to an
        #   inconsistency in the config described at
        #   https://collectionspace.atlassian.net/browse/DRYD-882
        # This was resolved in 7.0, but we keep it because this needs to support
        #   6.1 as well
        if rectype.profile.name.start_with?("publicart") &&
            rectype.name == "work"
          @fields = fields.reject { |f| f.name == "addressCounty" }
        end
      end

      def disabled?
        disabled = config.dig("disabled")
        disabled ? true : false
      end

      def enabled? = !disabled?

      def id
        "#{rectype.profile.name} #{rectype.name} #{name}"
      end

      def to_s
        "<##{self.class}:#{object_id.to_s(8)}\n"\
          "  id: #{id}\n"\
          "  disabled?: #{disabled?.inspect}\n"\
          "  fields: #{fields.length}>"
      end
      alias_method :inspect, :to_s

      private

      def get_form_fields
        CCU::Forms::Properties.new(self, config)
      end
    end
  end
end
