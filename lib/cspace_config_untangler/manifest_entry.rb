# frozen_string_literal: true

require "digest"
require "json"

module CspaceConfigUntangler
  class ManifestEntry
    def initialize(path:)
      @path = path.sub("//", "/")
    end

    def mapper_text = @mapper_text ||= File.read(path)

    def mapper_json = @mapper_json ||= JSON.parse(mapper_text)

    def digest
      Digest::SHA256.hexdigest(mapper_text)
    end

    def filename = File.basename(@path, ".json")

    attr_reader :path

    def profile = mapper_json.dig("config", "profile_basename")

    def recordtype
      [mapper_json.dig("config", "recordtype"),
        mapper_json.dig("config", "authority_subtype")
          &.tr("_", "-")].compact
        .join("-")
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

    def version = mapper_json.dig("config", "version")
  end
end
