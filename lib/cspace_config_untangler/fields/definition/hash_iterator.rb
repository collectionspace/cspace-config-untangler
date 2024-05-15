# frozen_string_literal: true

require_relative "field_filter"
require_relative "grouping"
require_relative "hash_entry_typer"

module CspaceConfigUntangler
  module Fields
    module Definition
      class HashIterator
        # @param config [CCU::Fields::Definition::Config]
        def initialize(config, called_from)
          @config = config
          clean_config_hash
          @caller = called_from
          @typer = HashEntryTyper.new(@config)
          parse_fields
        end

        private

        def clean_config_hash
          old_hash = @config.hash.dup
          return if old_hash.length == 1

          cleaned_hash = old_hash.except("[config]")
          @config.update_field_hash(cleaned_hash)
        end

        def namespace
          @config.namespace.literal
        end

        def parse_fields
          @config.hash.each { |name, data| parse_field(name, data) }
        end

        def parse_field(name, data)
          type = @typer.call(data)
          return unless type

          config = @config.derive_child(name: name, field_hash: data,
            parent: @caller)
          if type == :field || type == :structured_date
            FieldFilter.call(config)
          elsif type == :group
            Grouping.new(config)
          end
        end
      end
    end
  end
end
