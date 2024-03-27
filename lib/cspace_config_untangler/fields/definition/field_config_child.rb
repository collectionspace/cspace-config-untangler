# frozen_string_literal: true

require_relative "config"

module CspaceConfigUntangler
  module Fields
    module Definition
      class FieldConfigChild
        attr_reader :name, :ns, :ns_for_id, :id,
          :schema_path,
          :repeats, :in_repeating_group

        # @param config [CCU::Fields::Definition::Config]
        def initialize(config)
          @config = config
          @hash = config.hash
          @parent = config.parent

          @name = config.name
          @ns = @parent.config.namespace.literal
          @ns_for_id = @parent.config.namespace.for_id
          update_id_ns
          #      binding.pry if @name == 'visualPreferencesList'
          @id = get_id
          get_message("name") if @id
          get_message("fullName") if @id
          @schema_path = set_schema_path
          @repeats = set_repeats
          @in_repeating_group = set_group_repeats
        end

        def is_structured_date?
          return true if @hash.dig("[config]",
            "dataType") == "DATA_TYPE_STRUCTURED_DATE"
          return true if @hash.dig("dateLatestDay")
          false
        end

        private

        def update_id_ns
          @ns_for_id = "ext.#{@hash["extensionName"]}" if @hash.dig("extensionName")
          @ns_for_id = "ext.#{@hash["[config]"]["extensionName"]}" if @hash.dig(
            "[config]", "extensionName"
          )
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
          id = @hash.dig("[config]", "messages", "name", "id")
          id = @hash.dig("[config]", "messages", "fullName", "id") if id.nil?

          if id
            # the following account for typos in the ui config
            id = id.gsub("acquistion", "acquisition")
            id = id.sub("despositor", "depositor")
            id = id.sub("webAddressTypeType", "webAddressType")
            id = id.sub("graveAssocCodes", "graveAssocCode")
            id = id.sub("persons_common.forename", "persons_common.foreName")
            id = id.sub("persons_common.surname", "persons_common.surName")
            id = id.sub("propagations_common", "propagation_common")
            # match form used in namespace/subpaths
            id = id.sub("_naturalhistory.", "_naturalhistory_extension.")
          end

          if id
            id.sub("field.", "").sub(/\.name$/, "").sub(".fullName",
              "")
          end
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
