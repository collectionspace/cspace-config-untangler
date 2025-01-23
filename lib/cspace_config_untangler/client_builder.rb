# frozen_string_literal: true

require "collectionspace/client"

module CspaceConfigUntangler
  class ClientBuilder
    class << self
      def call(...) = new(...).call
    end

    # @param profile_basename [String] profile name with version info stripped
    #   off
    def initialize(profile_basename)
      @name = profile_basename
      @config = CCU.client_connection_config&.dig(name)
    end

    def call
      unless clientable?
        raise "#{name} profile not configured for services API connection"
      end

      client = CollectionSpace::Client.new(
        CollectionSpace::Configuration.new(**params)
      )
      check_connection(client)
    end

    private

    attr_reader :name, :config

    def clientable?
      return false if CCU.disable_api_checks

      community_supported? || configured?
    end

    def check_connection(client)
      result = client.get("accounts/0/accountperms")
    rescue SocketError
      raise "CollectionSpace::Client cannot connect. Check base_uri."
    else
      case result.status_code
      when 200
        client
      when 401
        raise "CollectionSpace::Client user does not have permission to "\
          "access read-only information in instance. Check credentials."
      else
        raise "#{result.status_code} : #{result.parsed}"
      end
    end

    def community_supported?
      CCU.community_supported_profiles.include?(name)
    end

    def configured?
      true if config
    end

    def params
      return community_supported_params if community_supported?

      config.transform_keys(&:to_sym)
    end

    def community_supported_params
      {base_uri: community_supported_uri,
       username: "reader@#{name}.collectionspace.org",
       password: "reader"}
    end

    def community_supported_uri
      subdomain = [name, community_supported_subdomain].compact
        .join(".")
      "https://#{subdomain}.collectionspace.org/cspace-services"
    end

    def community_supported_subdomain
      env = CCU.instance_env
      return if env == :demo

      env.to_s
    end
  end
end
