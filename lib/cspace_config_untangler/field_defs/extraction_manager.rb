# frozen_string_literal: true

require_relative "../namespace"
require_relative "iterator"

module CspaceConfigUntangler
  # Namespace for classes dealing with the extraction/gathering of all
  # field definitions from recordTypes/{recordType}/fields/document
  module FieldDefs
    # Handles (1) setting the initial record type namespace; (2)
    # kicking off iterative extraction for each included namespace in
    # field definition hash; and (3) gathering all extracted FieldDefs
    # and the intermediate Configs used to extract them
    class ExtractionManager
      # @return [CspaceConfigUntangler::RecordType]
      attr_reader :rectype

      # @return [Hash] from JSON config: recordtype/fields/document
      attr_reader :config

      # @return [String]
      attr_reader :ns

      # @return [Array<CCU::Fields::Def::FieldDefinition>]
      attr_reader :field_defs

      # @return [Array<CCU::Fields::Def::Config> used for debugging, testing
      attr_reader :configs

      # Top-level children of the config that we do not extract fields from
      SKIPPABLE_NAMESPACES = ["[config]", "ns2:collectionspace_core",
        "rel:relations-common-list"]

      # @param rectypeobj [CspaceConfigUntangler::RecordType]
      # @param fields_config [Hash, nil]
      def initialize(rectypeobj, fields_config = nil, iterator = nil)
        @rectype = rectypeobj
        @config = fields_config || rectypeobj.config.dig("fields", "document")
        @ns = CCU::Namespace.new(
          value: config.dig("[config]", "view", "props", "defaultChildSubpath"),
          rectype: rectype.name,
          profile: rectype.profile.name
        ).literal
        @field_defs = []
        @config_keys = {}
        @iterator = CCU::FieldDefs::Iterator.new(self)
      end

      def call
        config.each do |namespace, ns_field_hash|
          next if SKIPPABLE_NAMESPACES.any?(namespace)

          iterator.call(
            name: namespace,
            config: ns_field_hash,
            mode: :namespace
          )
        end
        self
      end

      def add_field_def(field_def) = field_defs << field_def

      def add_config(config) = configs << config

      class << self
        def call(...)
          new(...).call
        end
      end

      private

      attr_reader :iterator
    end
  end
end
