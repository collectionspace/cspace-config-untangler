# frozen_string_literal: true

module CspaceConfigUntangler
  module RecordTypes
    class ServiceConfig
      def initialize(hash)
        @hash = hash || {}
      end

      def service_name
        @service_name || @hash.dig("serviceName")
      end

      def service_path
        @service_path || @hash.dig("servicePath")
      end

      def service_type
        @service_type || @hash.dig("serviceType")
      end

      def object_name
        @object_name || @hash.dig("objectName")
      end

      def document_name
        @document_name || @hash.dig("documentName")
      end
    end
  end
end
