# frozen_string_literal: true

require_relative "../../ucbable"

module CspaceConfigUntangler
  module Fields
    module Definition
      class HashEntryTyper
        include Ucbable

        # @param config [CCU::Fields::Definition::Config]
        def initialize(config)
          @config = config
        end

        # @param hash [Hash]
        # @return [:field, :structured_date, :group]
        def call(hash)
          return :field if field?(hash)
          return :structured_date if structured_date?(hash)
          return :group if group?(hash)

          warn(hash)
        end

        private

        attr_reader :config

        def field?(hash)
          hash.keys == ["[config]"]
        end

        def group?(hash)
          hash.keys.length > 1
        end

        def structured_date?(hash)
          true if hash.dig("[config]", "dataType") ==
            "DATA_TYPE_STRUCTURED_DATE" ||
            hash.dig("dateLatestDay")
        end

        def warn(hash)
          return if vestigial_annotation_author?(hash)

          prefix = "field definition structure".upcase
          name = hash.dig("[config]", "messages", "name", "defaultMessage")
          message = if name
            "Unexpected field definition structure for "\
              "#{config.signature} - #{name}"
          else
            "Unexpected field definition structure under "\
              "#{config.signature}"
          end
          CCU.log.warn("#{prefix}: #{message}")
        end
      end
    end
  end
end
