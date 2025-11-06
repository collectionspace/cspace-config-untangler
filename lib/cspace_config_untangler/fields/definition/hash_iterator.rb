# frozen_string_literal: true

require_relative "grouping"
require_relative "hash_entry_typer"

module CspaceConfigUntangler
  module Fields
    module Definition
      # Takes a field definition {Config} (either representing namespace,
      # field grouping, or field), along with its parent, and iterates
      # through them to get all individual field definitions
      class HashIterator
        # List of fields to omit from resulting field definitions
        OMITTED_FIELDS = %w[csid inAuthority refName shortIdentifier]

        # @param config [CCU::Fields::Definition::Config]
        # @param called_from [CCU::Fields::Definition::NamespaceFieldParser,
        #   CCU::Fields::Definition::Grouping]
        def self.call(config, called_from)
          new(config, called_from).call
        end

        # @param config [CCU::Fields::Definition::Config]
        # @param called_from [CCU::Fields::Definition::NamespaceFieldParser,
        #   CCU::Fields::Definition::Grouping]
        def initialize(config, called_from)
          @config = config
          @caller = called_from
          @typer = HashEntryTyper.new(@config)
        end

        def call
          capture_config_key
          delete_config_key if config.hash.size > 1
          parse_fields
        end

        private

        attr_reader :config, :caller, :typer, :namespace

        def capture_config_key
          configkey = "[config]"
          return unless config.hash.key?(configkey)

          config.parser.add_config_key(config, config.hash[configkey])
        end

        def delete_config_key
          configkey = "[config]"
          return unless config.hash.key?(configkey)

          working = CCU.safe_copy(config.hash)
          working.delete(configkey)
          config.update_field_hash(working)
        end

        def parse_fields
          config.hash.each { |name, data| parse_field(name, data) }
        end

        def parse_field(name, data)
          type = typer.call(data)
          return unless type

          child = config.derive_child(name: name, field_hash: data,
            parent: caller)
          if type == :field || type == :structured_date
            build_and_add_field(child)
          elsif type == :group
            Grouping.call(child)
          end
        end

        def build_and_add_field(child)
          return if OMITTED_FIELDS.any?(child.name)

          field_def = FieldDefinition.new(child)
          return unless field_def

          config.parser.add_field_def(field_def)
        end
      end
    end
  end
end
