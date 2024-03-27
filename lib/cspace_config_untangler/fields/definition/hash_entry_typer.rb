# frozen_string_literal: true

module CspaceConfigUntangler
  module Fields
    module Definition
      class HashEntryTyper
        # @param config [CCU::Fields::Definition::Config]
        def initialize(config)
          @config = config
        end

        def call(hash)
          return :field if field?(hash)
          return :structured_date if structured_date?(hash)
          return :group if group?(hash)

          warn
        end

        private

        def field?(hash)
          hash.keys == ["[config]"]
        end

        def group?(hash)
          hash.keys.length > 1
        end

        def structured_date?(hash)
          return true if hash.dig("[config]",
            "dataType") == "DATA_TYPE_STRUCTURED_DATE"
          return true if hash.dig("dateLatestDay")
          false
        end

        def warn
          prefix = "field definition structure".upcase
          message = "Unexpected keys in"
          CCU.log.warn("#{prefix}: #{message} #{@config.signature}")
        end
      end
    end
  end
end
