# frozen_string_literal: true

module CspaceConfigUntangler
  module Report
    class ProfileMultiAuthFields
      include ByProfileable

      class << self
        def call(...)
          self.new(...).call
        end
      end

      # @param profiles [String]
      # @param release [String]
      def initialize(profiles:, release: CCU.release)
        @profiles = CCU::Cli::Helpers::ProfileGetter.call(profiles)
        @release = release
        @basedir = CCU.data_reference_dir(release)
        @basefilename = "_multi_auth_fields.csv"
        @all = all_multi_auth_fields
      end

      def call
        profiles.each do |profile|
          rows = rows_for(profile)
            .map{ |row| CCU::Report.simplify_allfields(row) }

          to_csv(profile, rows)
        end
      end

      private

      attr_reader :profiles, :release, :basedir, :basefilename, :all

      def all_multi_auth_fields
        path = CCU::Report.multi_auth_report_path
        unless File.exist?(path)
          CCU::Report::MultiAuthRepeatableFieldsGenerator.call(release: release)
        end
        CSV.parse(File.read(path), headers: true)
      end

      def rows_for(profile)
        all.select{ |row| row["profile"] == profile }
      end
    end
  end
end
