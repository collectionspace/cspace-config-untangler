# frozen_string_literal: true

require "fileutils"
require "selenium-webdriver"

module CspaceConfigUntangler
  # Automates the process of downloading, renaming, and reformatting UI JSON
  #   config files for the community-supported profiles
  class ConfigFetcher
    class << self
      def call(...) = new(...).call
    end

    # @param profile_basename [String] profile name with version info stripped
    #   off
    # @param target_dir [String] path to directory where config should be saved
    def initialize(profile_basename, target_dir = CCU.release_configs_dir)
      @name = profile_basename
      @target_dir = target_dir
      FileUtils.mkdir(target_dir) unless Dir.exist?(target_dir)

      profile = Selenium::WebDriver::Firefox::Profile.new
      profile["browser.download.folderList"] = 2
      profile["browser.download.dir"] = target_dir
      profile["browser.helperApps.neverAsk.openFile"] = "application/json"
      profile["browser.helperApps.neverAsk.saveToDisk"] = "application/json"

      options = Selenium::WebDriver::Options.firefox
      options.profile = profile

      @driver = Selenium::WebDriver.for :firefox, {options: options}
      @saved_name = "cspace-ui-config.json"
      @client = CCU.get_client(name)
    end

    def call
      driver.get(community_supported_uri)
      @version = client.version.ui.joined
      puts "Retrieving #{target_name} ..."
      driver.find_element(link_text: "Save configuration as JSON").click
      rename_file
      driver.quit
      CCU::UiConfig.reformat(target_path)
      target_path
    end

    private

    attr_reader :name, :target_dir, :driver, :version, :saved_name, :client

    def target_name = "#{version}.json"

    def target_path = File.join(target_dir, target_name)

    def saved_path = File.join(target_dir, saved_name)

    def rename_file
      raise "Config file for #{name} not saved" unless File.exist?(saved_path)

      FileUtils.remove_file(target_path) if File.exist?(target_path)
      FileUtils.mv(saved_path, target_path)
    end

    def community_supported?
      CCU.community_supported_profiles.include?(name)
    end

    def community_supported_uri
      subdomain = [name, community_supported_subdomain].compact
        .join(".")
      "https://#{subdomain}.collectionspace.org/cspace/#{name}/config"
    end

    def community_supported_subdomain
      env = CCU.instance_env
      return if env == :demo

      env.to_s
    end
  end
end
