# frozen_string_literal: true

require_relative "helpers"

module CspaceConfigUntangler
  module Cli
    class SubcommandBase < Thor
      include CCU::Cli::Helpers

      def self.banner(command, namespace = nil, subcommand = false)
        "#{basename} #{subcommand_prefix} #{command.usage}"
      end

      def self.subcommand_prefix
        name.gsub(%r{.*::}, "").gsub(%r{^[A-Z]}) do |match|
          match[0].downcase
        end.gsub(%r{[A-Z]}) { |match| "-#{match[0].downcase}" }
      end

      class_option :profiles,
        desc: "Comma-separated list (NO SPACES) of non-main profiles you "\
        "want to process. If not set, will run main profile only. If `all`, "\
        "will run all known profiles.",
        type: :string,
        default: CCU.main_profile,
        aliases: "-p"

      class_option :rectypes,
        desc: "Comma separated list (no spaces) of record types to include. "\
        "Defaults to all.",
        type: :array,
        default: ["all"],
        aliases: "-r"
    end
  end
end
