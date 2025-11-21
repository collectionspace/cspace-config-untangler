# frozen_string_literal: true

require_relative "config"
require_relative "../../messages"

module CspaceConfigUntangler
  module Fields
    module Definition
      class FieldConfigChild
        attr_reader :config, :name, :ns, :ns_for_id, :id,
          :schema_path,
          :repeats, :in_repeating_group

        # @param config [CCU::Fields::Definition::Config]
        def initialize(config)
          @config = config
          @hash = config.hash
          @parent = config.parent

          @name = config.name
          @ns = @parent.ns
          @ns_for_id = if @parent.respond_to?(:ns_for_id)
            @parent.ns_for_id
          else
            @ns
          end
          @id = get_id

          @messages = CCU::Messages.new
          get_message("name") if @id
          get_message("fullName") if @id
          @schema_path = set_schema_path
          @repeats = set_repeats
          @in_repeating_group = set_group_repeats
          @messages_extracted = false
        end

        def messages
          extract_messages unless messages_extracted
          @messages
        end

        def is_structured_date?
          return true if @hash.dig("[config]",
            "dataType") == "DATA_TYPE_STRUCTURED_DATE"
          return true if @hash.dig("dateLatestDay")
          false
        end

        private

        attr_reader :messages_extracted

        def extract_messages
          return unless id

          msg_config = @hash.dig("[config]", "messages")
          return unless msg_config

          @messages.add(msg_config)
        end

        def set_schema_path
          if @parent.is_a?(CCU::Fields::Def::NamespaceFieldParser)
            []
          else
            @parent.schema_path.clone
          end
        end

        def get_message(key)
          messages = @config.messages
          id = "field." + @id

          messages[id] = {} unless messages.has_key?(id)

          messages[id][key] =
            @hash.dig("[config]", "messages", key, "defaultMessage")
        end

        def get_id
          id = @hash.dig("[config]", "messages", "name", "id") ||
            @hash.dig("[config]", "messages", "fullName", "id")

          return nil unless id

          # the following account for typos in the ui config
          untypo = id.gsub("acquistion", "acquisition")
            .sub("despositor", "depositor")
            .sub("webAddressTypeType", "webAddressType")
            .sub("graveAssocCodes", "graveAssocCode")
            .sub("persons_common.forename", "persons_common.foreName")
            .sub("persons_common.surname", "persons_common.surName")
            .sub("propagation_common", "propagations_common")
            # match form used in namespace/subpaths
            .sub("_naturalhistory.", "_naturalhistory_extension.")

          id = if @config.rectype == "location" && name == "conditionGroup"
            untypo.sub("persons_", "locations_")
          else
            untypo
          end

          id.split(".")[1..-2].join(".")
        end

        def set_repeats
          if @hash.dig("[config]", "repeating") == true
            "y"
          else
            "n"
          end
        end

        def set_group_repeats
          if @parent.is_a?(CCU::Fields::Def::NamespaceFieldParser)
            "n/a"
          elsif @parent.repeats == "y"
            "y"
          elsif @parent.repeats == "n" && @parent.in_repeating_group == "y"
            "as part of larger repeating group"
          else
            "n"
          end
        end
      end
    end
  end
end
