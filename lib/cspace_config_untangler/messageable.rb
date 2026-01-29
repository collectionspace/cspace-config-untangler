# frozen_string_literal: true

require_relative "messages"

module CspaceConfigUntangler
  # Mixin module to set up messages instance variable and handle
  #   message extraction
  #
  # IMPLEMENTATION:
  # Each including class must:
  #
  # - Call `message_setup` in its :initialize method
  # - Define an `extract_messages` method that populates @messages the first
  #   time the `messages` method is called.
  module Messageable
    def self.included(klass)
      define_method(:message_setup) do
        instance_variable_set(:@messages, CCU::Messages.new)
        instance_variable_set(:@messages_extracted, false)
      end
    end

    # @param msgs [CCU::Messages]
    def add_messages(msgs) = @messages.add(msgs)

    def messages
      unless @messages_extracted
        extract_messages
        apply_overrides if self.class.private_method_defined?(:apply_overrides)
        @messages_extracted = true
      end

      @messages
    end
  end
end
