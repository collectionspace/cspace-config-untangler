# frozen_string_literal: true

module CspaceConfigUntangler
  module Report
    class ProfileStructuredDateFields
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
        @basedir = CCU.data_reference_dir(release)
        @basefilename = "_structured_date_fields.csv"
        @all = all_date_fields
      end

      def call
        profiles.each { |profile| to_csv(profile, rows_for(profile)) }
      end

      private

      attr_reader :profiles, :release, :basedir, :basefilename, :all

      def all_date_fields
        path = CCU::Report.structured_date_report_path
        unless File.exist?(path)
          CCU::Report::StructuredDateFieldsGenerator.call(release: release)
        end
        CSV.parse(File.read(path), headers: true)
      end

      def rows_for(profile)
        all.select { |row| row["profile"] == profile }
      end
    end
  end
end
