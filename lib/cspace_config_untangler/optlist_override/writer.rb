# frozen_string_literal: true

require_relative "../hosted"

require "json"

module CspaceConfigUntangler
  module OptlistOverride
    class Writer
      include JsonWritable

      def self.call(...) = self.new(...).call

      # @param configpath [String] to tenant UI config
      def initialize(configpath)
        @configpath = Pathname.new(configpath)
        @hash = {
          "config" => {
            "dataConfigType" => "optlist overrides",
          },
          "optlists" => {}
        }
      end

      def call
        puts "Creating #{configname} data_config..."
        set_tenant_basename
        optlists.each { |name, config| extract_options(name, config) }
        to_json(data: hash, output: targetpath)
      end

      private

      attr_reader :configpath, :hash

      def configname = @configname ||= configpath.basename.to_s

      def set_tenant_basename
        value = CCU::Hosted.subdomain(configname.delete_suffix(".json"))
        @hash["config"]["tenant_basename"] = value
      end

      def optlists
        return @optlists if instance_variable_defined?(:@optlists)

        config = JSON.parse(File.read(configpath))
        @optlists = config.fetch("optionLists", nil)
      end

      def extract_options(name, config)
        msgs = config["messages"]
        return unless msgs

        val = msgs.map { |k, v| [k, v["defaultMessage"]] }.to_h
        @hash["optlists"][name] = val
      end

      def targetpath = File.join(CCU.oo_data_config_path, configname)
    end
  end
end
