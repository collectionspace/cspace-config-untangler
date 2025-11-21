# frozen_string_literal: true

require_relative "../ucbable"
require_relative "iterative_field_extractor"

module CspaceConfigUntangler
  module Forms
    class Form
      ::CCU::Form = CspaceConfigUntangler::Forms::Form
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
        @messages = CCU::Messages.new
        @fields_extracted = false
        @messages_extracted = false
        return if disabled?

        # CCU::Forms::Properties.new(self, field_config)
        @iterator = CCU::Forms::IterativeFieldExtractor.new(self, field_config)
      end

      def fields
        extract_fields unless disabled? || @fields_extracted
        @fields
      end

      def messages
        return @messages if disabled?

        extract_fields unless @fields_extracted
        extract_messages unless @messages_extracted
        @messages
      end

      def field_config = config["template"]["props"]

      # param field [CCU::Forms::Field]
      def add_field(field) = fields << field

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
        @messages_extracted = true
        return unless config.key?("messages")

        @messages.add(config["messages"])
        rectype.add_messages(@messages)
      end

      def force_disabled?
        ucb_wrongly_inherited_form?(self) || false
      end
    end
  end
end
