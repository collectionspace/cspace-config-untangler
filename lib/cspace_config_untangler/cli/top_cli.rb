# frozen_string_literal: true

require_relative "helpers"

require_relative "authorities"
require_relative "configs"
require_relative "debug"
require_relative "fields"
require_relative "forms"
require_relative "mappers"
require_relative "oo"
require_relative "profiles"
require_relative "rectypes"
require_relative "reports"
require_relative "templates"
require_relative "vocabs"

module CspaceConfigUntangler
  module Cli
    class TopCli < Thor
      include CCU::Cli::Helpers

      def self.exit_on_failure?
        true
      end

      desc "authorities SUBCOMMAND", "Get info about authority vocabularies"
      subcommand "authorities", CCU::Cli::Authorities

      desc "configs SUBCOMMAND",
        "Commands to retrieve and manipulate JSON config files"
      subcommand "configs", CCU::Cli::Configs

      desc "debug SUBCOMMAND",
        "Commands useful for digging into why CCU is producing its results"
      subcommand "debug", CCU::Cli::Debug

      desc "fields SUBCOMMAND",
        "Info/reports on fields in specified profiles/rectypes"
      subcommand "fields", CCU::Cli::Fields

      desc "forms SUBCOMMAND",
        "Info/reports on forms in specified profiles/rectypes"
      subcommand "forms", CCU::Cli::Forms

      desc "mappers SUBCOMMAND",
        "Produce or work with JSON RecordMappers, as used by "\
        "cspace-batch-import"
      subcommand "mappers", CCU::Cli::Mappers

      if CCU.lyrasis_staff
        desc "oo SUBCOMMAND",
          "Generate/update optionlist override data configs"
        subcommand "oo", CCU::Cli::Oo
      end

      desc "profiles SUBCOMMAND",
        "Get info about and manipulate the profiles (i.e. CSpace application "\
        "configs)"
      subcommand "profiles", CCU::Cli::Profiles

      desc "rectypes SUBCOMMAND", "Work with record types"
      subcommand "rectypes", CCU::Cli::Rectypes

      desc "reports SUBCOMMAND", "Generate reports"
      subcommand "reports", CCU::Cli::Reports

      desc "templates SUBCOMMAND",
        "Generate CSV templates for preparing data for cspace-batch-import"
      subcommand "templates", CCU::Cli::Templates

      desc "vocabs SUBCOMMAND",
        "Get info about vocabularies (dynamic term lists)"
      subcommand "vocabs", CCU::Cli::Vocabs

      # desc 'test', 'temporary stuff for expediency'
      # def test
      #   profile = 'botgarden_1_0_0'
      #   rt = 'collectionobject'
      #   rm = RecordMapping.new(profile: profile, rectype: rt)
      # end
    end
  end
end
