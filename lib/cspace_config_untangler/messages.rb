# frozen_string_literal: true

require "forwardable"

require_relative "message_id"

module CspaceConfigUntangler
  class Messages
    # @return [Array<CCU::Message>]
    attr_reader :all

    SIMPLE_KEYS = %w[id defaultMessage].freeze

    CATEGORY_KEYS = CCU::MessageId::BASE_ID_SEGMENTS.keys
      .map(&:to_s)
      .freeze

    extend Forwardable
    def_delegators :@all, :size, :find

    def initialize
      @all = []
    end

    def add(config, parent: nil)
      if config.is_a?(CCU::Messages)
        @all.concat(config.all)
      elsif simple_cfg?(config)
        @all << CCU::Message.new(config, parent: parent)
      elsif typed_cfg?(config)
        handle_typed_cfg(config)
      elsif named_cfgs?(config)
        config.values.each { |cfg| add(cfg) }
      else
        raise "Unknown messages config pattern"
      end
    end

    def ids = all.map(&:full_id).sort

    # @param type [Symbol] element type of Message objects to return
    # @return [Array<CCU::Message>]
    def by_element_type(type) = all.select { |m| m.element_type == type }

    # @return [Array<Symbol>] element types of existing Message objects
    def element_types = all.map(&:element_type).uniq.sort

    def by_element_name(element_type, element_name)
      msgs = by_element_type(element_type).select do |m|
        m.element_name == element_name
      end

      case msgs.length
      when 0
        CCU.log.warning("No message found for #{element_type} #{element_name}")
        nil
      when 1
        msgs.first
      else
        CCU.log.warning("Multiple messages found for #{element_type} "\
                        "#{element_name}. Used first.")
        msgs.first
      end
    end

    def inspect
      %(#<#{self.class}:#{object_id} size: #{size}>)
    end

    private

    def simple_cfg?(config) = config.is_a?(Hash) &&
      config.keys == SIMPLE_KEYS

    def typed_cfg?(config)
      keys = config.keys
      CATEGORY_KEYS.intersection(keys) == keys.sort
    end

    def named_cfgs?(config)
      config.values.all? { |cfg| simple_cfg?(cfg) }
    end

    def handle_typed_cfg(config)
      config.values.each do |type|
        type.values.each { |cfg| add(cfg) }
      end
    end
  end
end
