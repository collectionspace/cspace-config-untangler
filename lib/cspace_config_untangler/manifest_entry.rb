# frozen_string_literal: true

require "digest"
require "json"

module CspaceConfigUntangler
  class ManifestEntry
    def initialize(path:, type:)
      @path = path.sub("//", "/")
      @type = type
    end

    def data_config_text = @data_config_text ||= File.read(path)

    def data_config_json = @data_config_json ||= JSON.parse(data_config_text)

    def data_config_type = @type

    def mode = @mode ||= set_mode

    def digest
      return unless data_config_type == "record type"

      Digest::SHA256.hexdigest(data_config_text)
    end

    def filename = File.basename(@path, ".json")

    attr_reader :path

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

    private

    def set_mode
      dataconfigtype = data_config_json.dig("config", "dataConfigType")
      return :old unless dataconfigtype
      return unless dataconfigtype == "record type"

      :new
    end

    def profile
      case data_config_type
      when "record type"
        data_config_json.dig("config", "profile_basename")
      when "optlist overrides"
        data_config_json.dig("config", "tenant_basename")
      end
    end

    def recordtype
      case data_config_type
      when "record type"
        (mode == :old) ? get_recordtype_old : get_recordtype_new
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
        @path.to_s.delete_prefix(CCU.oo_data_config_path)
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
      end
    end

    def get_recordtype_old
      [data_config_json.dig("config", "recordtype"),
        data_config_json.dig("config", "authority_subtype")
          &.tr("_", "-")].compact
        .join("-")
    end

    def get_recordtype_new = data_config_json.dig("config", "display_name")

    def valid?
      return true if data_config_type == "optlist overrides"

      v = RecordMapper::Validator.new(@path)
      v.validate
      v.valid
    end

    def version = data_config_json.dig("config", "version")
  end
end
