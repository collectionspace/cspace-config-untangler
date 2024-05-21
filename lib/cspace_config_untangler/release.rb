# frozen_string_literal: true

module CspaceConfigUntangler
  class Release
    attr_reader :version

    # @param version [nil, String] CollectionSpace application release version
    #   in format #_# or #_#_#
    def initialize(version = nil, switch: true)
      CCU::Validate.release(version) if version
      @version = version || CCU.releases.last
      @index = CCU.releases.index(@version)
      switch_release if switch
    end

    def gt(other_version)
      index > CCU::Release.new(other_version, switch: false).index
    end

    def gte(other_version)
      return true if other_version == version

      gt(other_version)
    end

    def lt(other_version)
      index < CCU::Release.new(other_version, switch: false).index
    end

    def lte(other_version)
      return true if other_version == version

      lt(other_version)
    end

    def previous
      prev_idx = index - 1
      return nil if prev_idx < 0

      CCU.releases[prev_idx]
    end

    def next
      return nil if CCU.releases.last == version

      CCU.releases[index + 1]
    end

    def to_s = version || ""

    protected

    attr_reader :index

    private

    def switch_release
      clear_config_dir
      move_release_to_config_dir
    end

    def clear_config_dir
      configs = Dir.new(CCU.configdir)
        .children
        .select { |filename| clearable?(filename) }
        .map { |filename| File.join(CCU.configdir, filename) }
      FileUtils.rm(configs)
    end

    def community_supported_profile?(filename)
      CCU.community_supported_profiles.include?(filename.split("_").first)
    end

    def clearable?(filename)
      filename.end_with?(".json") && community_supported_profile?(filename)
    end

    def move_release_to_config_dir
      rel_cfg_dir = CCU.release_configs_dir(version)
      release_configs = Dir.new(rel_cfg_dir)
        .children
        .map { |fn| File.join(rel_cfg_dir, fn) }
      FileUtils.cp(release_configs, CCU.configdir)
    end
  end
end
