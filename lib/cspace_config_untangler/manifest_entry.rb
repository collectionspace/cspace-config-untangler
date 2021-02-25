require 'cspace_config_untangler'

module CspaceConfigUntangler
  class ManifestEntry
    def initialize(path:)
      @path = path.sub('//', '/')
    end

    def filename
      File.basename(@path, '.json')
    end

    def filename_parts
      filename.split('_')
    end

    def path
      @path
    end
    
    def profile
      filename_parts[0]
    end

    def recordtype
      filename_parts[2]
    end

    def subpath
      @path.delete_prefix(CCU::MAPPER_DIR)
        .sub(/^\/+/, '')
    end

    def to_h
      return nil unless valid?
      {
        'profile'=> profile,
        'version'=> version,
        'type'=> recordtype,
        'enabled'=> true,
        'url'=> "#{CCU::MAPPER_URI_BASE}/#{subpath}"
      }
    end

    def valid?
      v = RecordMapper::Validator.new(@path)
      v.validate
      v.valid
    end

    def version
      filename_parts[1]
    end
  end
end
