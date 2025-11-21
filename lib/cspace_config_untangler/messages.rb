# frozen_string_literal: true

require "forwardable"

require_relative "message_id"

module CspaceConfigUntangler
  class Messages
    attr_reader :all

    SIMPLE_KEYS = %w[id defaultMessage].freeze

    CATEGORY_KEYS = CCU::MessageId::BASE_ID_SEGMENTS.keys
      .map(&:to_s)
      .freeze

    extend Forwardable
    def_delegators :@all, :size

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
