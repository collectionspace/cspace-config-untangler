# frozen_string_literal: true

require_relative "hash_iterator"

module CspaceConfigUntangler
  module Fields
    module Definition
      # If the given {Config} is not for a blob or contact subrecord, does
      # nothing except calling {HashIterator} on the {Config}. If it is a
      # subrecord, replaces the Hash in {Config} with the subrecord-as-record
      # type field definiton hash (from recordTypes/{subrecord}) and
      # calls {HashIterator}
      #
      # @todo The existence of this as a separate class seems like an
      # example of past-me taking "single responsibility principle" a
      # little too literally. This is better handled in {Parser}.
      class NamespaceFieldParser
        # @return [CCU::Fields::Definition::Config]
        attr_reader :config

        # @param config [CCU::Fields::Definition::Config]
        def initialize(config)
          @config = config
          update_subrecord_field_hash
          HashIterator.new(@config, self)
        end

        def subrecord_config_hash(subrec_type, ns)
          @config.profile_config.dig("recordTypes", subrec_type, "fields",
            "document", ns)
        end

        def update_subrecord_field_hash
          ns = @config.namespace.literal
          if ns.start_with?("ns2:contacts_")
            @config.update_field_hash(subrecord_config_hash("contact", ns))
          elsif ns == ("ns2:blobs_common")
            @config.update_field_hash(subrecord_config_hash("blob", ns))
          end
        end
      end
    end
  end
end
