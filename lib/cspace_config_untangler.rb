# standard library
require 'csv'
require 'fileutils'
require 'json'
require 'logger'
require 'pp'
require 'yaml'

# external gems
require 'bundler/setup'
require 'dry-configurable'
require 'facets/kernel/blank'
require 'http'
require 'nokogiri'
require 'pry'
require 'thor'


module CspaceConfigUntangler
  ::CCU = CspaceConfigUntangler
  module_function
  extend Dry::Configurable

  # Change these variables to reflect your desired directory structure and main profile
  default_datadir = '/Users/kristina/code/cs/untangler-cspace-config/data'
  default_main_profile_name = 'core'
  # The publicly available web directory from which the CSV Importer will request mappers
  default_mapper_uri_base = 'https://raw.githubusercontent.com/collectionspace/cspace-config-untangler/main/data/mappers'
  # The last version of each profile that should get fancy column names created.
  default_last_fancy_column_versions = {
    'anthro' => '4-1-2',
    'bonsai' => '4-1-1',
    'botgarden' => '2-0-1',
    'core' => '6-1-0',
    'fcart' => '3-0-1',
    'herbarium' => '1-1-1',
    'lhmc' => '3-1-1',
    'hku' => '3-0-1',
    'materials' => '2-0-0',
    'ohc' => '1-0-4',
    'omca' => '6-1-0',
    'publicart' => '2-0-1',
  }
  # Don't change stuff after this

  File.delete('log.log') if File::exist?('log.log')

  def logger
    @logger ||= Logger.new('log.log')
  end

  def app_dir
    File.realpath(File.join(File.dirname(__FILE__), '..'))
  end

  # Do not mess with these. Control subdirectories within them by passing in command output parameters as
  #   shown in the docs
  default_configdir = File.join(default_datadir, 'configs')
  default_templatedir = File.join(default_datadir, 'templates')
  default_mapperdir = File.join(default_datadir, 'mappers')

  setting :last_fancy_column_versions, default: default_last_fancy_column_versions, reader: true
  setting :datadir, default: default_datadir, reader: true
  setting :configdir, default: default_configdir, reader: true
  setting :templatedir, default: default_templatedir, reader: true
  setting :mapperdir, default: default_mapperdir, reader: true
  setting :releases,
    default: {
      "5_2"=>nil,
      "6_0"=>"5_2",
      "6_1"=>"6_0",
      "7_0"=>"6_1",
      "7_1"=>"7_0",
      "7_2"=>"7_1"
    },
    reader: true
  setting :release,
    default: nil,
    reader: true,
    constructor: ->(value) do
      if value
        rel = CCU::Validate.release(value)
        CCU.switch_release(rel)
      else
        core = Dir.new(configdir)
          .children
          .select{ |filename| filename.start_with?("core") }
          .first
        rel = core.split("_")
          .last
          .split("-")
          .first(2)
          .join("_")
      end
      rel
    end
  setting :prev_release,
    default: nil,
    reader: true,
    constructor: ->(_v){ releases[release] }
  setting :main_profile_name, default: default_main_profile_name, reader: true
  setting :log, default: logger, reader: true
  setting :mapper_uri_base,
    default: default_mapper_uri_base,
    reader: true

  def allfields_path(
    release: CCU.release,
    outmode: :expert,
    datemode: :collapsed
  )
    vdatemode = CCU::Validate.date_mode(datemode)
    voutmode = CCU::Validate.out_mode(outmode)

    basename = "all_fields_#{release}_dates_#{vdatemode}"
    suffix = voutmode == :expert ? ".csv" : "_#{voutmode}.csv"
    File.join(
      data_reference_dir(release),
      "#{basename}#{suffix}"
    )
  end

  def data_reference_dir(release=CCU.release)
    File.join(
      app_dir,
      'data',
      'reference',
      release
    )
  end

  def release_configs_dir(release=CCU.release)
    File.join(app_dir, "data", "config_holder",
              "community_profiles", "release_#{release}")
  end

  def profiles
    Dir.new(CCU.configdir).children
      .reject{ |e| e['readable'] }
      .reject{ |e| e == '.keep' }
      .map{ |fn| File.basename(fn).sub('.json', '') }
  end

  def main_profile
    Pathname.new(CCU.configdir)
      .children(false)
      .select{ |filename| filename.to_s.start_with?(CCU.main_profile_name) }
      .map{ |filename| filename.to_s.delete_suffix(filename.extname) }
      .first
  end

  def safe_copy(hash)
    Marshal.load(Marshal.dump(hash))
  end

  def switch_release(release)
    clear_config_dir
    move_release_to_config_dir(release)
  end

  def clear_config_dir
    configs = Dir.new(CCU.configdir)
      .children
      .select{ |filename| filename.end_with?(".json") }
      .map{ |filename| File.join(CCU.configdir, filename) }
    FileUtils.rm(configs)
  end

  def move_release_to_config_dir(release)
    rel_cfg_dir = CCU.release_configs_dir(release)
    release_configs = Dir.new(rel_cfg_dir)
      .children
      .map{ |fn| File.join(rel_cfg_dir, fn) }
    FileUtils.cp(release_configs, CCU.configdir)
  end

  gem_agnostic_dir = $LOAD_PATH.select{ |dir| dir['untangler'] }.reject{ |dir| dir.end_with?('/spec') }.first

  # Require all application files
  Dir.glob("#{gem_agnostic_dir}/cspace_config_untangler/**/*").sort.select{ |path| path.match?(/\.rb$/) }.each do |rbfile|
    req_file = rbfile.delete_prefix("#{gem_agnostic_dir}/").delete_suffix('.rb')
    require req_file
  end
end
