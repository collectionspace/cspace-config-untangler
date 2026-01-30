# frozen_string_literal: true

require "forwardable"
require_relative "message_id"

module CspaceConfigUntangler
  class Message
    attr_reader :id, :message

    extend Forwardable
    def_delegators :@id, :orig_id, :base_id, :message_type, :element_name

    include Comparable

    # @param config [Hash]
    # @param parent [Hash, nil] broader config hash containing the message
    #   config, if there is needed additional info there
    def initialize(config, parent: nil)
      @config = config
      @parent = parent
      @id = CCU::MessageId.new(config["id"])
      @message = config["defaultMessage"]
    end

    def element_type = @element_type ||= set_element_type

    def update_message(newmsg)
      @message = newmsg
    end

    def inspect
      %(#<#{self.class}:#{object_id} id: #{orig_id}>)
    end

    def ==(other)
      signature == other.signature
    end
    alias_method :eql?, :==

    def signature = [base_id, message_type, message]

    def hash = [self.class, signature].hash

    private

    attr_reader :config, :parent

    def set_element_type
      return id.element_type unless parent

      :field_grouping if compound_input_parent?
    end

    def compound_input_parent?
      parent.dig("[config]", "view", "type") == "CompoundInput"
    end
  end
end
