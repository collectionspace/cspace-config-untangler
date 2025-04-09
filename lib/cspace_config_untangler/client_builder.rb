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
      @ssm = CCU.ssm_client
      @config = CCU.client_connection_config&.dig(name)
    end

    def call
      return if CCU.disable_api_checks

      unless clientable?
        raise "#{name} profile not configured for services API connection"
      end

      client = CollectionSpace::Client.new(
        CollectionSpace::Configuration.new(**params)
      )
      check_connection(client)
    end

    private

    attr_reader :name, :ssm, :config

    def clientable?
      return false if CCU.disable_api_checks

      community_supported? || ssm_params || configured?
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
      return ssm_params if ssm_params

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

    def ssm_params = @ssm_params ||= get_ssm_params

    def get_ssm_params
      paramname = "cspace-dcsp-production-#{name}-admin-password"
      response = ssm.get_parameter({name: paramname, with_decryption: true})
      @ssm_params = {base_uri: CCU::Hosted.services_url(name),
                     username: "admin@collectionspace.org",
                     password: response.parameter.value}
    rescue Aws::SSM::Errors::ParameterNotFound
      @ssm_params = nil
    end
  end
end
