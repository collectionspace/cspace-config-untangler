# frozen_string_literal: true

module CspaceConfigUntangler
  module Report
    class ProfileFieldsGenerator
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
        @basefilename = "_fields.csv"
        @all_fields = CCU::Report.get_all_fields(release: release)
      end

      def call
        profiles.each { |profile| to_csv(profile, rows_for(profile)) }
      end

      private

      attr_reader :profiles, :release, :basedir, :basefilename, :all_fields

      def rows_for(profile)
        all_fields.select { |row| row["profile"] == profile }
      end
    end
  end
end
