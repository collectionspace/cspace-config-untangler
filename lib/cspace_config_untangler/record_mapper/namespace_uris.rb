# frozen_string_literal: true

module CspaceConfigUntangler
  module RecordMapper
    # returns hash of namespaces in a document, and their namespace URIs
    # profile_config = Hash from CCU::Profile.config
    # rectype = String
    # mapper_config = Hash of mapper
    class NamespaceUris
      ::NamespaceUris = CspaceConfigUntangler::RecordMapper::NamespaceUris

      # rubocop:disable Layout/LineLength
      WEIRD_NS_LOOKUP = {
        "ns2:collectionobjects_annotation" =>
          "http://collectionspace.org/services/collectionobject/domain/"\
          "annotation",
        "ns2:groups_checklist" =>
          "http://collectionspace.org/services/group/domain/checklist",
        # OHC custom namespace
        "ns2:collectionobjects_anthro" =>
          "http://collectionspace.org/services/collectionobject/domain/anthro",
        # OMCA custom namespace
        "ns2:collectionobjects_anthropology" =>
          "http://collectionspace.org/services/collectionobject/domain/"\
          "anthropology",
        "ns2:collectionobjects_variablemedia" =>
          "http://collectionspace.org/services/collectionobject/domain/"\
          "collectionobject",
        "ns2:collectionobjects_fineart" =>
          "http://collectionspace.org/services/collectionobject/domain/"\
        "collectionobject",
        "ns2:concepts_fineart" =>
          "http://collectionspace.org/services/concept/domain/fineart",
        "ns2:conditionchecks_variablemedia" =>
          "http://collectionspace.org/services/conditioncheck/domain/variablemedia",
        "ns2:acquisitions_commission" =>
          "http://collectionspace.org/services/acquisition/domain/commission",
        "ns2:propagations_common" =>
          "http://collectionspace.org/services/propagation",
        "ns2:osteology_anthropology" =>
          "http://collectionspace.org/services/osteology/domain/anthropology"
      }
      # rubocop:enable Layout/LineLength

      def initialize(profile_config:, rectype:, mapper_config:)
        @config = profile_config
        @rectype = rectype
        @mconfig = mapper_config
      end

      def hash
        hash = {}
        @config.dig("recordTypes", @rectype, "fields", "document").keys
          .select { |k| k.start_with?("ns2") }
          .reject do |k|
          k == "ns2:collectionspace_core" ||
            k == "ns2:account_permission"
        end
          .each { |ns| hash[ns.sub("ns2:", "")] = uri(ns) }
        hash
      end

      private

      def authority_ns_uri(ns)
        @config.dig("recordTypes", @rectype, "fields", "document", ns,
          "csid", "[config]", "extensionParentConfig",
          "service", "ns")
      end

      def extension_ns_uri(ns)
        ext = ns.sub("ns2:#{@mconfig[:document_name]}_", "").sub("_extension",
          "")
        @config.dig("extensions", ext, object_name, "fields", ns, "[config]",
          "service", "ns")
      end

      def object_name
        return if @mconfig[:service_type] == "authority"

        @mconfig[:object_name].downcase
      end

      def uri(ns)
        case ns
        when "ns2:contacts_common"
          "http://collectionspace.org/services/contact"
        when "ns2:#{@mconfig[:document_name]}_common"
          if @mconfig[:service_type] == "authority"
            authority_ns_uri(ns)
          else
            "http://collectionspace.org/services/#{object_name}"
          end
        when "ns2:#{@mconfig[:document_name]}_#{@mconfig[:profile_basename]}"
          ["http://collectionspace.org", "services", object_name, "domain",
            @mconfig[:profile_basename]].join("/")
        else
          result = @config.dig("recordTypes", @rectype, "fields", "document",
            ns, "[config]", "service", "ns")

          return result if result

          WEIRD_NS_LOOKUP.key?(ns) ? WEIRD_NS_LOOKUP[ns] : extension_ns_uri(ns)
        end
      end
    end
  end
end
