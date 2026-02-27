# frozen_string_literal: true

module CspaceConfigUntangler
  module Report
    class ProfileAuthorityUse
      include ByProfileable

      class << self
        def call(...)
          new(...).call
        end
      end

      # @param profiles [String]
      # @param release [String]
      def initialize(profiles:, release: CCU.release)
        @profiles = CCU::Cli::Helpers::ProfileGetter.call(profiles)
        @release = release
        @source = CCU::Report.auth_vocab_report_path
        @basedir = CCU.data_reference_dir(release)
        @basefilename = "_authority_vocabulary_use.csv"
        @all = get_all_rows
      end

      def call
        profiles.each { |profile| write(profile) }
      end

      private

      attr_reader :profiles, :release, :source, :basedir, :basefilename,
        :all

      def get_all_rows
        unless File.exist?(source)
          CCU::Report::AuthorityVocabUse.call(profiles: profiles)
        end

        CSV.parse(File.read(source), headers: true)
      end

      def write(profile)
        rows = all.select { |row| row["profile"] == profile }
        return if rows.empty?

        to_csv(profile, rows)
      end
    end
  end
end
