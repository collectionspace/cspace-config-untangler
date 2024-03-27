# frozen_string_literal: true

require_relative "field_definition"

module CspaceConfigUntangler
  module Fields
    module Definition
      # Ensures some fields do not get included in the resulting field definitions
      class FieldFilter
        # List of fields to omit from resulting field definitions
        OmittedFields = %w[csid inAuthority refName shortIdentifier]

        # This allows us to to skip manually doing `new.call` every time
        def self.call(config)
          new.call(config)
        end

        # @param config [CCU::Fields::Definition::Config]
        def call(config)
          return if OmittedFields.any?(config.name)

          field_def = FieldDefinition.new(config)
          return unless field_def

          update_field_defs(config, field_def)
        end

        private

        def update_field_defs(config, field_def)
          config.parser.add_field_def(field_def)
        end
      end
    end
  end
end
