# frozen_string_literal: true

require_relative "../client_builder"

module CspaceConfigUntangler
  module Profiles
    # Makes API call to get `hasDocType` values for objecct, procedure, and
    #   authority service groups. The `hasDocType` value should match the
    #   `serviceConfig/objectName` value in record type configs.
    class ServiceGroupsGetter
      class << self
        def call(profilename)
          client = get_client(profilename)
          unless client.is_a?(CollectionSpace::Client)
            puts client
            return []
          end

          %w[object procedure authority].map { |grp| doc_types(grp, client) }
            .flatten
        end

        private

        def get_client(name)
          CCU::ClientBuilder.call(name)
        rescue RuntimeError => err
          "#{name}: #{err.message}"
        end

        def doc_types(grp, client)
          response = client.get("/servicegroups/#{grp}")

          unless response.result.success?
            raise "Cannot retrieve #{grp} services: #{response.result.code}"
          end

          types = response.parsed
            .dig("document", "servicegroups_common", "hasDocTypes")
          return types.values if types.respond_to?(:values)

          []
        end
      end
    end
  end
end
