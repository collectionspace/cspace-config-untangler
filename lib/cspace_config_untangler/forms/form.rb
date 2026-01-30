# frozen_string_literal: true

require_relative "../messageable"
require_relative "../message_overrideable"
require_relative "../ucbable"
require_relative "iterative_field_extractor"

module CspaceConfigUntangler
  module Forms
    class Form
      ::CCU::Form = CspaceConfigUntangler::Forms::Form
      include Messageable
      include MessageOverrideable
      include Ucbable
      attr_reader :rectype, :profile, :name, :config

      # @param rectypeobj [CCU:RecordType]
      # @param formname [String]
      def initialize(rectypeobj, formname)
        @rectype = rectypeobj
        @profile = rectype.profile
        @name = formname
        @config = rectype.config["forms"][name]
        @fields = []
        message_setup
        @fields_extracted = false
        return if disabled?

        # CCU::Forms::Properties.new(self, field_config)
        @iterator = CCU::Forms::IterativeFieldExtractor.new(self, field_config)
      end

      def fields
        return [] if disabled?

        extract_fields unless @fields_extracted
        @fields
      end

      def field_config = config["template"]["props"]

      # param field [CCU::Forms::Field]
      def add_field(field) = @fields << field

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

      def extract_fields
        @fields_extracted = true
        iterator.call
      end

      def extract_messages
        return if disabled?

        # This is required to get any field or subrecord-level messages
        extract_fields unless @fields_extracted
        return unless config.key?("messages")

        add_messages(config["messages"])
      end

      def apply_overrides
        overrides = profile.message_overrides
        return unless overrides

        overrides.select { |k, _v| k.start_with?("record.#{name}") }
          .each { |k, v| @messages.override(convert_to_config(k, v)) }
      end

      def force_disabled?
        ucb_wrongly_inherited_form?(self) || false
      end
    end
  end
end
