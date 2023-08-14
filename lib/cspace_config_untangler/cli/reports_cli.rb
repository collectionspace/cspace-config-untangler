require_relative 'helpers'

module CspaceConfigUntangler
  module Cli
    class ReportsCli < Thor
      include CCU::Cli::Helpers

      desc 'qa', 'Writes all QA reports to release directory'
      long_desc <<~LONG
        Requirements:

        - All profiles for release must be in the `configs` directory

        Generates the following:

        - De-versioned all fields reports for current and previous release, with
          structured date fields collapsed

        - Changed fields report
      LONG
      option :release,
        desc: 'Release being QAed (like 7_2)',
        type: :string,
        required: true,
        aliases: '-r'
      def qa
        CCU::Report.qa_reports(release: options[:release])
      end

      desc 'ref', 'Writes all reference reports to release directory'
      long_desc <<~LONG
        Requirements:

        - All profiles for release must be in the `configs` directory

        Generates the following:

        - all fields reports with structured date fields expanded and collapsed

        - a report of all fields for each profile (structured date fields collapsed)

        - repeatable multiple-authority fields report

        - list of all structured date fields
      LONG
      option :release,
        desc: 'Release (like 7_0)',
        type: :string,
        required: true,
        aliases: '-r'
      def ref
        CCU::Report.reference_reports(options[:release])
      end
    end
  end
end
