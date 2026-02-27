# frozen_string_literal: true

require "digest"

require_relative "subcommand_base"

module CspaceConfigUntangler
  module Cli
    class Oo < SubcommandBase
      desc "manifest",
        "Writes JSON manifest of optlist overrides data configs"
      def manifest
        opts = {
          inputdir: Pathname.new(CCU.oo_data_config_path),
          output: Pathname.new(File.join(CCU.datadir, "mapper_manifests",
            "optlist_overrides.json")),
          recursive: false,
          type: "optlist overrides"
        }

        puts "Building manifest with options:"
        opts.each { |key, val| puts "  #{key}: #{val}" }
        CCU::Manifest.new(**opts).build
      end

      desc "write",
        "Writes JSON optlist override data configs for the configs currently "\
        "in `CCU.oo_config_dir`"
      shared_option :output_dir, default: CCU.oo_data_config_path
      def write
        Dir.new(CCU.oo_config_dir).children
          .reject { |child| child == ".keep" }
          .each do |tenant|
            CCU::OptlistOverride::Writer.call(
              File.join(CCU.oo_config_dir, tenant)
            )
        end
      end
    end
  end
end
