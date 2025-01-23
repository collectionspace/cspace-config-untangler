# frozen_string_literal: true

require_relative "helpers"

module CspaceConfigUntangler
  module Cli
    class SubcommandBase < Thor
      include CCU::Cli::Helpers

      class << self
        def shared_options_config
          {
            structured_date: {
              desc: "expanded: report all individual structured date fields; "\
                "collapsed: report the parent of individual structured "\
                "date fields as the field",
              default: "expanded",
              aliases: "-d",
              type: :string
            },
            env: {
              desc: "Which site instances to run on; only works on "\
                "Lyrasis-hosted community-supported profiles",
              enum: %w[demo dev qa],
              type: :string,
              required: true,
              default: "demo",
              aliases: "-e"
            },
            input_dir: {
              desc: "Path to directory containing input files",
              type: :string,
              default: CCU.mapperdir,
              aliases: "-i",
              required: true
            },
            output_mode: {
              desc: "Output mode in which to run command",
              enum: %w[csv stdout],
              default: "stdout",
              type: :string,
              aliases: "-m"
            },
            output_dir: {
              desc: "Path to output directory",
              type: :string,
              default: nil,
              aliases: "-o"
            },
            output_path: {
              desc: "Path to output file",
              type: :string,
              default: nil,
              aliases: "-o"
            },
            profiles: {
              desc: "Comma-separated list (NO SPACES) of non-main profiles "\
                "you want to process. If not set, will run main profile only. "\
                "If `all`, will run all known profiles.",
              type: :string,
              default: CCU.main_profile,
              aliases: "-p"
            },
            rectypes: {
              desc: "Comma separated list (no spaces) of record types to "\
                "include.",
              type: :array,
              default: ["all"],
              aliases: "-r"
            },
            release: {
              desc: "Release (like 8_0)",
              type: :string,
              required: true,
              aliases: "-r"
            },
            subdirs: {
              desc: "Whether to organize into subdirectories within given "\
                "output directory by normalized profile name. Normalized "\
                "profile name is the profile with version info/underscores "\
                "removed.",
              type: :boolean,
              default: false,
              aliases: "-s"
            }
          }
        end

        def shared_options(*option_names)
          option_names.each do |option_name|
            opt = shared_options_config[option_name]
            if opt.nil?
              raise "Tried to access shared option '#{option_name}' but it "\
                "was not previously defined"
            end

            option option_name, opt
          end
        end

        def shared_option(option_name, **overrides)
          opt = shared_options_config[option_name]
          if opt.nil?
            raise "Tried to access shared option '#{option_name}' but it "\
              "was not previously defined"
          end

          option option_name, opt.merge(overrides)
        end
      end

      def self.banner(command, namespace = nil, subcommand = false)
        "#{basename} #{subcommand_prefix} #{command.usage}"
      end

      def self.subcommand_prefix
        name.gsub(%r{.*::}, "").gsub(%r{^[A-Z]}) do |match|
          match[0].downcase
        end.gsub(%r{[A-Z]}) { |match| "-#{match[0].downcase}" }
      end
    end
  end
end
