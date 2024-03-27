require "digest"

module CspaceConfigUntangler
  class ManifestEntry
    def initialize(path:)
      @path = path.sub("//", "/")
    end

    def digest
      Digest::SHA256.hexdigest(File.read(path))
    end

    def filename
      File.basename(@path, ".json")
    end

    def filename_parts
      filename.split("_")
    end

    attr_reader :path

    def profile
      filename_parts[0]
    end

    def recordtype
      filename_parts[2]
    end

    def subpath
      @path.delete_prefix(CCU.mapperdir)
        .sub(/^\/+/, "")
    end

    def to_h
      return nil unless valid?
      {
        "profile" => profile,
        "version" => version,
        "type" => recordtype,
        "digest" => digest,
        "enabled" => true,
        "url" => "#{CCU.mapper_uri_base}/#{subpath}"
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
