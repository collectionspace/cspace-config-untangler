# frozen_string_literal: true

# standard library
require "csv"
require "fileutils"
require "json"
require "logger"
require "yaml"

# external gems
require "bundler/setup"
require "dry-configurable"
require "facets/kernel/blank"
require "nokogiri"
require "pry"
require "thor"

require_relative "cspace_config_untangler/upgrade_warner"

module CspaceConfigUntangler
  ::CCU = CspaceConfigUntangler

  module_function

  extend Dry::Configurable

  # Change these variables to reflect your desired directory structure and main
  # profile
  default_main_profile_name = "core"

  # The publicly available web directory from which the CSV Importer will
  # request mappers
  default_mapper_uri_base =
    "https://raw.githubusercontent.com/collectionspace/"\
    "cspace-config-untangler/main/data/mappers"

  # The last version of each profile that should get fancy column names created.
  default_last_fancy_column_versions = {
    "anthro" => "4-1-2",
    "bonsai" => "4-1-1",
    "botgarden" => "2-0-1",
    "core" => "6-1-0",
    "fcart" => "3-0-1",
    "herbarium" => "1-1-1",
    "lhmc" => "3-1-1",
    "hku" => "3-0-1",
    "materials" => "2-0-0",
    "ohc" => "1-0-4",
    "omca" => "6-1-0",
    "publicart" => "2-0-1"
  }

  # The last version of each profile that should get plain (i.e. no
  # authority name and vocab name added to column header in template
  # and mapper.
  default_single_authority_plain_last_versions = {
    "anthro" => "7-0-0",
    "bonsai" => "5-0-6",
    "botgarden" => "3-0-6",
    "core" => "7-2-0",
    "fcart" => "6-0-0",
    "herbarium" => "2-0-9",
    "lhmc" => "6-0-0",
    "hku" => "1-0-0",
    "materials" => "3-2-0",
    "ohc" => "1-0-19",
    "omca" => "1-0-0-rc6",
    "publicart" => "5-0-0"
  }

  # @return [Boolean] set to false if you are non-Lyrasis staff using this tool,
  #   or are Lyrasis staff without access to dts-hosting Github resources
  setting :lyrasis_staff,
    default: nil,
    reader: true,
    constructor: ->(default) do
      return default unless default.nil?

      ghpath = `which gh`
      return false if ghpath.empty?

      orgs = `gh org list`
      return true if orgs.split("\n").include?("dts-hosting")

      false
    end

  # rubocop:disable Layout/LineLength

  # @return [nil, String] path to YAML file containing credentials for
  #   CollectionSpace::Client connections. Defaults to
  #   `#{user home dir}/.config/cspace-config-untangler/client_connection_config.yml`
  setting :client_connection_config_path,
    default: nil,
    reader: true,
    constructor: ->(default) do
      return default if default

      home = File.expand_path("~")
      full = File.join(home, ".config", "cspace-config-untangler",
        "client_connection_config.yml")
      return full if File.exist?(full)

      nil
    end
  # rubocop:enable Layout/LineLength

  # Don't change stuff after this

  def app_dir
    File.realpath(File.join(File.dirname(__FILE__), ".."))
  end

  # Do not mess with these. Control subdirectories within them by
  # passing in command output parameters as shown in the docs
  default_datadir = File.join(app_dir, "data")
  default_configdir = File.join(default_datadir, "configs")
  default_templatedir = File.join(default_datadir, "templates")
  default_mapperdir = File.join(default_datadir, "mappers")
  default_logpath = File.join(app_dir, "log.log")

  setting :last_fancy_column_versions,
    default: default_last_fancy_column_versions, reader: true
  setting :single_authority_plain_last_versions,
    default: default_single_authority_plain_last_versions,
    reader: true
  setting :community_supported_profiles,
    default: %w[core anthro bonsai botgarden fcart herbarium lhmc materials
      publicart],
    reader: true
  setting :datadir, default: default_datadir, reader: true
  setting :configdir, default: default_configdir, reader: true
  setting :templatedir, default: default_templatedir, reader: true
  setting :mapperdir, default: default_mapperdir, reader: true
  setting :logpath, default: default_logpath, reader: true
  setting :releases,
    default: ["5_2", "6_0", "6_1", "7_0", "7_1", "7_2", "8_0", "8_1", "8_1_1",
      "8_2"],
    reader: true

  setting :release,
    default: nil,
    reader: true,
    constructor: ->(value) do
      return value if value.is_a?(CCU::Release)
      return CCU::Release.new(value) if value

      CCU::Release.new(releases.last, switch: false)
    end

  setting :prev_release,
    default: nil,
    reader: true,
    constructor: ->(_v) { release.previous }
  setting :main_profile_name, default: default_main_profile_name, reader: true
  setting :mapper_uri_base,
    default: default_mapper_uri_base,
    reader: true
  setting :optlist_override_uri_base,
    default: "https://raw.githubusercontent.com/collectionspace/"\
    "cspace-config-untangler/main/data/optlist_overrides",
    reader: true

  File.delete(logpath) if File.exist?(logpath)

  setting :log,
    default: nil,
    reader: true,
    constructor: ->(default) { default || Logger.new(logpath) }

  setting :upgrade_warner,
    default: CCU::UpgradeWarner.new,
    reader: true

  # @return [:demo, :qa, :dev] Used when setting up a CollectionSpace::Client
  #   for community supported profiles.
  setting :instance_env, default: :demo, reader: true,
    constructor: ->(default) { default.to_sym }

  setting :client_connection_config,
    default: nil,
    reader: true,
    constructor: ->(_default) do
      return nil unless client_connection_config_path

      YAML.load_file(client_connection_config_path)
    end

  # @return [Boolean] mainly used to improve test performance. Most tests do
  #   not rely on api checks and they slow down the test suite significantly.
  #   This is set to true across the board in spec_helper and can be
  #   overridden per-test as needed.
  setting :disable_api_checks, default: false, reader: true

  def allfields_path(
    release: CCU.release,
    outmode: :expert,
    datemode: :collapsed
  )
    vdatemode = CCU::Validate.date_mode(datemode)
    voutmode = CCU::Validate.out_mode(outmode)

    basename = "all_fields_#{release}_dates_#{vdatemode}"
    suffix = (voutmode == :expert) ? ".csv" : "_#{voutmode}.csv"
    File.join(
      data_reference_dir(release),
      "#{basename}#{suffix}"
    )
  end

  def data_reference_dir(release = CCU.release.version)
    File.join(
      app_dir,
      "data",
      "reference",
      release.to_s
    )
  end

  def release_configs_dir(release = CCU.release.version)
    File.join(app_dir, "data", "config_holder",
      "community_profiles", "release_#{release}")
  end

  def profiles
    Dir.new(CCU.configdir).children
      .reject { |e| e["readable"] }
      .reject { |e| e == ".keep" }
      .map { |fn| File.basename(fn).sub(".json", "") }
  end

  def main_profile
    Pathname.new(CCU.configdir)
      .children(false)
      .select { |filename| filename.to_s.start_with?(CCU.main_profile_name) }
      .map { |filename| filename.to_s.delete_suffix(filename.extname) }
      .first
  end

  # Look up the versioned config name available for the given profile basename
  # @param basename [String] like "core" or "anthro"
  # @return [String, nil]
  def profile_for(basename)
    comm = profiles.select do |profile|
      profile.start_with?(basename)
    end
    return comm.first unless comm.empty?

    for_api_profile = CCU.client_connection_config&.dig(basename, "profile")
    return unless for_api_profile

    profiles.find { |profile| profile.start_with?(for_api_profile) }
  end

  def get_client(profile_basename)
    CCU::ClientBuilder.call(profile_basename)
  rescue RuntimeError => err
    "#{profile_basename}: #{err.message}"
  end

  setting :ssm_client,
    default: nil,
    reader: true,
    constructor: ->(default) do
      return if !lyrasis_staff || disable_api_checks

      CHIA.ssm_client
    end

  def safe_copy(hash)
    Marshal.load(Marshal.dump(hash))
  end

  # The following section is relevant only to Lyrasis staff with access to the
  #   dts-hosting Github organization

  # @return [String] path to local directory for dts-hosting/deployments
  #   Github repository
  setting :oo_instance_repo_path,
    default: File.expand_path("~/code/lyr/deployments"),
    reader: true

  setting :oo_site_config_path,
    default: File.join(oo_instance_repo_path, "sites", "collectionspace",
      "config"),
    reader: true

  setting :oo_config_dir,
    default: File.join(Bundler.root, "data", "config_holder", "temp"),
    reader: true

  setting :oo_data_config_path,
    default: File.join(datadir, "optlist_overrides"),
    reader: true

  gem_agnostic_dir = $LOAD_PATH.select do |dir|
    dir["untangler"]
  end.reject { |dir| dir.end_with?("/spec") }.first

  # Require all application files
  Dir.glob("#{gem_agnostic_dir}/cspace_config_untangler/**/*")
    .sort
    .select do |path|
      path.match?(/\.rb$/)
    end.each do |rbfile|
      req_file = rbfile.delete_prefix("#{gem_agnostic_dir}/")
        .delete_suffix(".rb")
      require req_file
    end

  if lyrasis_staff
    chia_path = File.join(Bundler.root, "vendor",
      "cspace_hosted_instance_access")
    unless Dir.exist?(chia_path)
      FileUtils.cd(File.join(Bundler.root, "vendor")) do
        `gh repo clone dts-hosting/cspace_hosted_instance_access`
      end
    end

    FileUtils.cd(chia_path) do
      unless `git status`.match?("branch is up to date")
        `git pull`
        `bundle install`
      end
    end

    require File.join(chia_path, "lib", "cspace_hosted_instance_access")
  end
end
