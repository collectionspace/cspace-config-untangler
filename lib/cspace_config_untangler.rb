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
require "http"
require "nokogiri"
require "pry"
require "thor"

module CspaceConfigUntangler
  ::CCU = CspaceConfigUntangler

  module_function

  extend Dry::Configurable

  # Change these variables to reflect your desired directory structure and main
  # profile
  default_datadir = "/Users/kristina/code/cs/untangler-cspace-config/data"
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
    "hku" => "",
    "materials" => "3-2-0",
    "ohc" => "1-0-19",
    "omca" => "1-0-0-rc6",
    "publicart" => "5-0-0"
  }

  # Don't change stuff after this

  def app_dir
    File.realpath(File.join(File.dirname(__FILE__), ".."))
  end

  # Do not mess with these. Control subdirectories within them by
  # passing in command output parameters as shown in the docs
  default_configdir = File.join(default_datadir, "configs")
  default_templatedir = File.join(default_datadir, "templates")
  default_mapperdir = File.join(default_datadir, "mappers")
  default_logpath = File.join(app_dir, "log.log")

  setting :last_fancy_column_versions,
    default: default_last_fancy_column_versions, reader: true
  setting :single_authority_plain_last_versions,
    default: default_single_authority_plain_last_versions,
    reader: true
  setting :datadir, default: default_datadir, reader: true
  setting :configdir, default: default_configdir, reader: true
  setting :templatedir, default: default_templatedir, reader: true
  setting :mapperdir, default: default_mapperdir, reader: true
  setting :logpath, default: default_logpath, reader: true
  setting :releases,
    default: ["5_2", "6_0", "6_1", "7_0", "7_1", "7_2", "8_0"],
    reader: true
  setting :release,
    default: nil,
    reader: true,
    constructor: ->(value) { CCU::Release.new(value) }
  setting :prev_release,
    default: nil,
    reader: true,
    constructor: ->(_v) { release.previous }
  setting :main_profile_name, default: default_main_profile_name, reader: true
  setting :mapper_uri_base,
    default: default_mapper_uri_base,
    reader: true

  File.delete(logpath) if File.exist?(logpath)
  # def logger
  #   @logger ||= Logger.new(logpath)
  # end
  setting :log,
    default: nil,
    reader: true,
    constructor: ->(default) { default ||= Logger.new(logpath) }

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
      release
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

  def safe_copy(hash)
    Marshal.load(Marshal.dump(hash))
  end

  def switch_release(release)
    clear_config_dir
    move_release_to_config_dir(release)
  end

  # @param target_version [String] of release for which warnings should be
  #   emitted
  # @param issue [nil, String] Jira or other issue to check for information on
  #   the status of changes expected to impact this code
  def warn_on_upgrade(target_version:, issue: nil)
    return unless release.version == target_version

    basemsg = "Verify that code at the following location is still "\
      "needed with #{target_version}"
    msgissue = issue ? "(see #{issue})" : nil
    fullmsg = [basemsg, msgissue].compact.join(" ")
    warn([fullmsg, caller(1..1).first].compact.join(":\n"))
  end

  gem_agnostic_dir = $LOAD_PATH.select do |dir|
    dir["untangler"]
  end.reject { |dir| dir.end_with?("/spec") }.first

  # Require all application files
  Dir.glob("#{gem_agnostic_dir}/cspace_config_untangler/**/*")
    .sort
    .select do |path|
      path.match?(/\.rb$/)
    end.each do |rbfile|
      req_file = rbfile.delete_prefix("#{gem_agnostic_dir}/").delete_suffix(".rb")
      require req_file
    end
end
