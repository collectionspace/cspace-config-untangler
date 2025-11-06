# frozen_string_literal: true

require_relative "field_config_child"
require_relative "hash_iterator"

module CspaceConfigUntangler
  module Fields
    module Definition
      class Grouping < FieldConfigChild
        # @param config [CCU::Fields::Definition::Config]
        def self.call(config)
          new(config).call
        end

        attr_reader :config, :repeats

        # @param config [CCU::Fields::Definition::Config]
        def initialize(config)
          super
          @schema_path << config.name
        end

        def call = HashIterator.call(config, self)
      end
    end
  end
end
