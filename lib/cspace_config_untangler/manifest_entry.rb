# frozen_string_literal: true

require "digest"
require "json"

module CspaceConfigUntangler
  class ManifestEntry
    def initialize(path:)
      @path = path.sub("//", "/")
    end

    def data_config_text = @data_config_text ||= File.read(path)

    def data_config_json = @data_config_json ||= JSON.parse(data_config_text)

    def data_config_type = @data_config_type ||=
      data_config_json.dig("config", "dataConfigType")

    def digest
      Digest::SHA256.hexdigest(data_config_text)
    end

    def filename = File.basename(@path, ".json")

    attr_reader :path

    def profile = data_config_json.dig("config", "profile_basename")

    def recordtype
      case data_config_type
      when "record type"
        [data_config_json.dig("config", "recordtype"),
         data_config_json.dig("config", "authority_subtype")
         &.tr("_", "-")].compact
          .join("-")
      when "optlist overrides"
        nil
      end
    end

    def subpath
      case data_config_type
      when "record type"
        @path.delete_prefix(CCU.mapperdir)
          .sub(/^\/+/, "")
      when "optlist overrides"
        @path.delete_prefix(CCU.oo_data_config_path)
          .sub(/^\/+/, "")
      end
    end

    def url
      case data_config_type
        when "record type"
          "#{CCU.mapper_uri_base}/#{subpath}"
      when "optlist overrides"
        "#{CCU.optlist_override_uri_base}/#{subpath}"
      end
    end

    def enabled
      case data_config_type
      when "record type"
        true
      else
        nil
      end
    end

    def to_h
      return nil unless valid?
      h = {
        "profile" => profile,
        "version" => version,
        "type" => recordtype,
        "digest" => digest,
        "enabled" => enabled,
        "url" => url,
        "dataConfigType" => data_config_type
      }
      h.compact
    end

    def valid?
      return true if data_config_type == "optlist overrides"

      v = RecordMapper::Validator.new(@path)
      v.validate
      v.valid
    end

    def version = data_config_json.dig("config", "version")
  end
end
