# frozen_string_literal: true

require_relative "field_config_child"
require_relative "field_filter"
require_relative "hash_iterator"

module CspaceConfigUntangler
  module Fields
    module Definition
      class Grouping < FieldConfigChild
        attr_reader :config, :repeats

        # @param config [CCU::Fields::Definition::Config]
        def initialize(config)
          super
          @schema_path << config.name

          HashIterator.new(config, self)
        end
      end
    end
  end
end
