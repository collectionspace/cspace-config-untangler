# frozen_string_literal: true

require_relative "config"
require_relative "namespace_field_parser"

module CspaceConfigUntangler
  module Fields
    module Definition
      class Parser
        attr_reader :rectype, :config, :field_defs

        # Namespaces we do not extract fields from
        SKIPPABLE_NAMESPACES = ["[config]", "ns2:collectionspace_core",
          "rel:relations-common-list"]

        # @param rectypeobj [CspaceConfigUntangler::RecordType]
        # @param fields_config [Hash] from JSON config: record
        #   type/fields/document/config
        def initialize(rectypeobj, fields_config)
          @rectype = rectypeobj
          @config = fields_config
          @ns = @config["[config]"]["view"]["props"]["defaultChildSubpath"]
          @field_defs = []
          namespace_field_defs
        end

        # @param field_def [CCU::Fields::Def::FieldDefinition]
        def add_field_def(field_def)
          @field_defs << field_def
        end

        private

        def namespace_field_defs
          @config.each do |namespace, ns_field_hash|
            next if SKIPPABLE_NAMESPACES.any?(namespace)

            namespace_field_config = CCU::Fields::Def::Config.new(
              rectype: @rectype,
              namespace: namespace,
              field_hash: ns_field_hash,
              parser: self
            )
            CCU::Fields::Def::NamespaceFieldParser.new(namespace_field_config)
          end
        end
      end
    end
  end
end
