# frozen_string_literal: true

require_relative "../ucbable"

module CspaceConfigUntangler
  module Forms
    # Logs any unknown/unhandled keys, and any unexpected values of known
    # keys in a props hash.
    #
    # This will hopefully alert us of any changes to patterns that need to
    # be handled in the config, instead of there just being errors somewhere
    # in the processing
    #
    # @todo add more validations
    class PropsValidator
      include Ucbable

      # Keys that may not be nil or empty if present
      CONTENT_KEYS = %w[children name props subpath].freeze
      EMPTY_KEYS = %w[key ref _owner].freeze
      DISPLAY_KEYS = %w[collapsed collapsible defaultMessage embedded id label
        showDetachButton style
        tabular type values].freeze
      KNOWN_KEYS = (CONTENT_KEYS + EMPTY_KEYS + DISPLAY_KEYS).freeze

      # To update this, run `ccu forms props_key_sigs -p all`
      KNOWN_KEYSIGS = [
        ["_owner", "key", "props", "ref", "type"],
        ["_owner", "key", "props", "ref"],
        ["children", "collapsed", "collapsible", "name"],
        ["children", "collapsible", "name"],
        ["children", "name", "subpath"],
        ["children", "name", "tabular"],
        ["children", "name"],
        ["children", "style"],
        ["children", "subpath", "tabular"],
        ["children"],
        ["defaultMessage", "id", "values"],
        ["embedded", "label", "name"],
        ["multiline", "name"],
        ["name", "showDetachButton"],
        ["name", "subpath"],
        ["name"],
        ["style"]
      ]

      # To update this, run `ccu forms subpaths -p all -m code`
      KNOWN_SUBPATHS = [["ns2:collectionobjects_common",
        "objectCountGroupList", "objectCountGroup", "0"],
        "ns2:acquisitions_commission", "ns2:acquisitions_lhmc",
        "ns2:acquisitions_publicart", "ns2:claims_nagpra",
        "ns2:collectionobjects_accessionattributes",
        "ns2:collectionobjects_accessionuse",
        "ns2:collectionobjects_annotation",
        "ns2:collectionobjects_anthro", "ns2:collectionobjects_bonsai",
        "ns2:collectionobjects_botgarden",
        "ns2:collectionobjects_culturalcare",
        "ns2:collectionobjects_fineart",
        "ns2:collectionobjects_herbarium",
        "ns2:collectionobjects_materials",
        "ns2:collectionobjects_nagpra",
        "ns2:collectionobjects_naturalhistory_extension",
        "ns2:collectionobjects_publicart",
        "ns2:collectionobjects_variablemedia", "ns2:concepts_fineart",
        "ns2:conditionchecks_lhmc", "ns2:conditionchecks_publicart",
        "ns2:conditionchecks_variablemedia", "ns2:conservation_bonsai",
        "ns2:conservation_livingplant", "ns2:conservation_publicart",
        "ns2:exhibitions_lhmc", "ns2:exhibitions_publicart",
        "ns2:groups_checklist", "ns2:intakes_lhmc",
        "ns2:loansin_herbarium", "ns2:loansin_lhmc",
        "ns2:loansin_naturalhistory_extension",
        "ns2:loansout_botgarden", "ns2:loansout_herbarium",
        "ns2:loansout_lhmc", "ns2:loansout_naturalhistory_extension",
        "ns2:locations_publicart", "ns2:media_materials",
        "ns2:media_publicart", "ns2:movements_botgarden",
        "ns2:movements_lhmc", "ns2:objectexit_naturalhistory_extension",
        "ns2:organizations_publicart", "ns2:osteology_anthropology",
        "ns2:persons_lhmc", "ns2:persons_publicart", "ns2:places_lhmc",
        "ns2:places_nagpra", "ns2:places_publicart",
        "ns2:taxon_herbarium", "ns2:valuationcontrols_publicart",
        "rel:relations-common-list"]

      def initialize
      end

      # @param props [CCU::Forms::Props]
      def call(props)
        content_keys_populated(props)
        check_keysigs(props)
        # check_assumed_empty_keys(props)
      end

      private

      def content_keys_populated(props)
        props.keys
          .intersection(CONTENT_KEYS)
          .each do |key|
            val = props.config[key]
            next unless val.nil? || val.empty?

            CCU.log.info("FORM STRUCTURE: EMPTY #{key.upcase}: "\
                         "#{props.warning_id} (#{__FILE__}, #{__LINE__}")
            props.add_warning(:"empty_#{key}")
          end
      end

      def check_keysigs(props)
        keysig = props.keys.sort
        return if KNOWN_KEYSIGS.include?(keysig)
        return if namespace_wrapper_props?(props.config)

        CCU.log.error("FORM STRUCTURE: UNKNOWN PROPS KEYSIG: "\
                      "#{keysig.inspect} in #{props.warning_id}. "\
                      "Add treatment handling in Forms::Props. "\
                    "(#{__FILE__}, #{__LINE__}")
        props.add_error(:unknown_keysig)
      end

      def check_assumed_empty_keys(props)
        EMPTY_KEYS.each do |key|
          next unless props.config.key?(key)
          next unless props.config[key]

          report(props)
        end
      end

      def report(props)
        puts props.form.inspect
        puts props.inspect
        puts props.config
        puts ""
      end

      def formatted_key(props, key) = "#{props.warning_id} #{key}"
    end
  end
end
