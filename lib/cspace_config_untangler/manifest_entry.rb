require 'cspace_config_untangler'

module CspaceConfigUntangler
  class ManifestEntry
    def initialize(path:)
      @path = path
    end

    def filename
      File.basename(@path, '.json')
    end

    def subpath
      @path.delete_prefix(CCU::MAPPER_DIR)
        .sub(/^\/+/, '')
    end
  end
end
