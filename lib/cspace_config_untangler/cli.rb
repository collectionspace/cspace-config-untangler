# frozen_string_literal: true

require_relative "cli/authorities_cli"
require_relative "cli/debug_cli"
require_relative "cli/fields_cli"
require_relative "cli/forms_cli"
require_relative "cli/helpers"
require_relative "cli/mappers_cli"
require_relative "cli/profiles_cli"
require_relative "cli/rectypes_cli"
require_relative "cli/reports_cli"
require_relative "cli/templates_cli"

module CspaceConfigUntangler
  module Cli
    class CommandLine < Thor
      include CCU::Cli::Helpers
      def self.exit_on_failure?
        true
      end

      desc "authorities SUBCOMMAND", "Get info about authority vocabularies"
      subcommand "authorities", CCU::Cli::AuthoritiesCli

      desc "debug SUBCOMMAND",
        "Commands useful for digging into why CCU is producing its results"
      subcommand "debug", CCU::Cli::DebugCli

      desc "fields SUBCOMMAND",
        "Info/reports on fields in specified profiles/rectypes"
      subcommand "fields", CCU::Cli::FieldsCli

      desc "forms SUBCOMMAND",
        "Info/reports on forms in specified profiles/rectypes"
      subcommand "forms", CCU::Cli::FormsCli

      desc "mappers SUBCOMMAND",
        "Produce or work with JSON RecordMappers, as used by cspace-batch-import"
      subcommand "mappers", CCU::Cli::MappersCli

      desc "profiles SUBCOMMAND",
        "Get info about and manipulate the profiles (i.e. CSpace application configs)"
      subcommand "profiles", CCU::Cli::ProfilesCli

      desc "rectypes SUBCOMMAND", "Work with record types"
      subcommand "rectypes", CCU::Cli::RecTypesCli

      desc "reports SUBCOMMAND", "Generate reports"
      subcommand "reports", CCU::Cli::ReportsCli

      desc "templates SUBCOMMAND",
        "Generate CSV templates for preparing data for cspace-batch-import"
      subcommand "templates", CCU::Cli::TemplatesCli

      class_option :profiles,
        desc: 'Comma-separated list (NO SPACES) of non-main profiles you want to process. If not set, will run main profile only. If "all", will run all known profiles.',
        type: "string",
        default: CCU.main_profile,
        aliases: "-p"

      # desc 'test', 'temporary stuff for expediency'
      # def test
      #   profile = 'botgarden_1_0_0'
      #   rt = 'collectionobject'
      #   rm = RecordMapping.new(profile: profile, rectype: rt)
      # end
    end
  end
end
