# frozen_string_literal: true

require "json"

module CspaceConfigUntangler
  module UiConfig
    module_function

    def fetch_community_profiles(release: CCU.release.version,
      env: CCU.instance_env)
      CCU.config.release = release unless CCU.release.version == release
      CCU.config.instance_env = env
      CCU.community_supported_profiles.each do |profile|
        CCU::ConfigFetcher.call(profile)
      end
    end

    def fetch_hosted(tenants)
      return unless CCU.lyrasis_staff

      to_fetch = tenants || CHIA.tenant_names
      to_fetch.each do |tenant|
        CCU::ConfigFetcher.call(tenant, CCU.oo_config_dir)
      end
    end

    # @param path [String] to JSON config
    def reformat(path)
      json = JSON.parse(File.read(path))
      File.open(path, "w") do |outfile|
        outfile.puts(JSON.pretty_generate(json))
      end
    end
  end
end
