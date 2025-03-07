# frozen_string_literal: true

require_relative "../ucbable"
require_relative "iterative_field_extractor"

module CspaceConfigUntangler
  module Forms
    class Form
      ::CCU::Form = CspaceConfigUntangler::Forms::Form
      include Ucbable
      attr_reader :rectype, :profile, :name, :config, :fields

      # @param rectypeobj [CCU:RecordType]
      # @param formname [String]
      def initialize(rectypeobj, formname)
        @rectype = rectypeobj
        @profile = rectype.profile
        @name = formname
        @config = rectype.config["forms"][name]
        @fields = []
        return if disabled?

        # CCU::Forms::Properties.new(self, field_config)
        @iterator = CCU::Forms::IterativeFieldExtractor.new(self, field_config)
      end

      def extract_fields = iterator.call

      def field_config = config["template"]["props"]

      # param field [CCU::Forms::Field]
      def add_field(field)
        return if ignored?(field)

        fields << field
      end

      def disabled?
        disabled = config.dig("disabled")
        disabled ? true : force_disabled?
      end

      def enabled? = !disabled?

      def id
        "#{profile.name} #{rectype.name} #{name}"
      end

      def to_s
        "<##{self.class}:#{object_id.to_s(8)} #{id} form; "\
          "disabled?: #{disabled?.inspect}; fields: #{fields.length}>"
      end
      alias_method :inspect, :to_s

      private

      attr_reader :iterator

      def force_disabled?
        ucb_wrongly_inherited_form?(self) || false
      end

      # @todo move to Props.skippable?
      def ignored?(field)
        # This logic loop prevents failure for of publicart work due to an
        # inconsistency in the config described at
        # https://collectionspace.atlassian.net/browse/DRYD-882. This was
        # resolved in 7.0, but we keep it because this needs to support
        # 6.1 as well
        true if field.name == "addressCounty" &&
          rectype.name == "work" &&
          profile.name.start_with?("publicart") &&
          CCU.release.lt("7_0")
      end
    end
  end
end
