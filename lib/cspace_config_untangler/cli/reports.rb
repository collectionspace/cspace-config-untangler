# frozen_string_literal: true

require_relative "subcommand_base"

module CspaceConfigUntangler
  module Cli
    class Reports < SubcommandBase
      remove_class_option :profiles, :rectypes

      desc "qa", "Writes all QA reports to release directory"
      long_desc <<~LONG
        Requirements:

        - All profiles for release must be in the `configs` directory

        Generates the following:

        - De-versioned all fields reports for current and previous release, with
          structured date fields collapsed

        - Changed fields report
      LONG
      shared_options :release, :env
      def qa
        CCU::Report.qa_reports(release: options[:release],
          env: options[:env])
      end

      desc "ref", "Writes all reference reports to release directory"
      long_desc <<~LONG
        Requirements:

        - All profiles for release must be in the `configs` directory

        Generates the following:

        - all fields reports with structured date fields expanded and collapsed

        - a report of all fields for each profile (structured date fields collapsed)

        - repeatable multiple-authority fields report

        - list of all structured date fields
      LONG
      shared_options :release, :env
      def ref
        CCU::Report.reference_reports(release: options[:release],
          env: options[:env])
      end
    end
  end
end
