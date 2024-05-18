# frozen_string_literal: true

module CspaceConfigUntangler
  module Fields
    module Definition
      # little class to handle namespace logic
      #
      # The namespaces used to define fields in the `document` section
      #   are not always the same used in the field ids, so we need to
      #   keep the `literal` and `for_id` namespaces together but
      #   separate
      class Namespace
        # @return [String]
        attr_reader :literal

        # For-id namespace values that can be assigned simply based on
        # literal namespace value
        FOR_ID_BY_LITERAL = {
          "ns2:collectionobjects_accessionuse" => "ext.accessionuse",
          "ns2:propagations_common" => "ns2:propagation_common",
          "ns2:conditionchecks_variablemedia" => "ext.technicalChanges",
          "ns2:acquisitions_commission" => "ext.commission"
        }

        # @param namespace [String]
        # @param hash [Hash]
        def initialize(namespace, hash = nil)
          @literal = namespace
          @config = hash
        end

        def for_id
          @for_id ||= id_namespace
        end

        private

        attr_reader :config

        def id_namespace
          return FOR_ID_BY_LITERAL[literal] if FOR_ID_BY_LITERAL.key?(literal)
          return "ext.#{extensionname}" if extensionname

          return from_name_message if name_messages?
          literal
        end

        def extensionname
          return unless config

          config.dig("[config]", "extensionName")
        end

        def name_messages?
          return false unless config

          true if config.dig("[config]", "messages", "fullName") ||
            config.dig("[config]", "messages", "name")
        end

        def from_name_message
          result = [config.dig("[config]", "messages", "fullName", "id"),
            config.dig("[config]", "messages", "name", "id")].compact
          return result if result.empty?

          result.first
            .split(".")[1..-3]
            .join(".")
        end
      end
    end
  end
end
