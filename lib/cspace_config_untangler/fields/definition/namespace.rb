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
        attr_reader :literal
        def initialize(namespace)
          @literal = namespace
        end

        def for_id
          @for_id ||= id_namespace
        end

        private

        def id_namespace
          case literal
          when "ns2:collectionobjects_accessionuse"
            "ext.accessionuse"
          when "ns2:propagations_common"
            "ns2:propagation_common"
          when "ns2:conditionchecks_variablemedia"
            "ext.technicalChanges"
          when "ns2:acquisitions_commission"
            "ext.commission"
          else
            literal
          end
        end
      end
    end
  end
end
