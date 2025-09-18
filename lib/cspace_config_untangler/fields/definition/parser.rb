# frozen_string_literal: true

require_relative "config"
require_relative "namespace_field_parser"

module CspaceConfigUntangler
  module Fields
    module Definition
      # Coordinates the extraction/gathering of all field definitions from
      # recordTypes/{recordType}/fields/document
      #
      # The child keys at this level (for anthro collectionobject) are:
      #
      # - [config]
      # - ns2:collectionspace_core
      # - rel: relations-common-list
      # - ns2:collectionobjects_annotation
      # - ns2:collectionobjects_common
      # - ns2:collectionobjects_anthro
      # - ns2:collectionobjects_culturalcare
      # - ns2:collectionobjects_nagpra
      # - ns2:collectionobjects_naturalhistory_extension
      #
      # The overall namespace (@ns) is derived from:
      # [config]/view/props/defaultChildSubpath
      #
      # Otherwise we call each of the children of this level a namespace,
      # skip the skippable ones, and call {NamespaceFieldParser} on each.
      class Parser
        # @return [CspaceConfigUntangler::RecordType]
        attr_reader :rectype

        # @return [Hash] from JSON config: recordtype/fields/document
        attr_reader :config

        # @return [Array<CCU::Fields::Def::FieldDefinition>]
        attr_reader :field_defs

        # @return [Hash{CCU::Fields::Def::Config => Hash}] values of JSON
        #   objects having `[config]` key, nested in the field definition; used
        #   to verify we are not missing unexpectedly added info
        attr_reader :config_keys

        # Top-level children of the config that we do not extract fields from
        SKIPPABLE_NAMESPACES = ["[config]", "ns2:collectionspace_core",
          "rel:relations-common-list"]

        # @param rectypeobj [CspaceConfigUntangler::RecordType]
        # @param fields_config [Hash] from JSON config: record
        #   type/fields/document
        def initialize(rectypeobj, fields_config)
          @rectype = rectypeobj
          @config = fields_config
          @ns = config["[config]"]["view"]["props"]["defaultChildSubpath"]
          @field_defs = []
          @config_keys = {}
          namespace_field_defs
        end

        # @param field_def [CCU::Fields::Def::FieldDefinition]
        def add_field_def(field_def)
          field_defs << field_def
        end

        # @param configobj [CCU::Fields::Def::Config]
        # @param hash [Hash]
        def add_config_key(configobj, hash)
          config_keys[configobj.signature] = hash
        end

        private

        def namespace_field_defs
          config.each do |namespace, ns_field_hash|
            next if SKIPPABLE_NAMESPACES.any?(namespace)

            namespace_field_config = CCU::Fields::Def::Config.new(
              rectype: rectype,
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
