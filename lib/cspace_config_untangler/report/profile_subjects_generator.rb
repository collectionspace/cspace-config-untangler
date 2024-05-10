# frozen_string_literal: true

module CspaceConfigUntangler
  module Report
    class ProfileSubjectsGenerator
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
        @basefilename = "_subject_fields.csv"
        @all_fields = CCU::Report.get_all_fields(release: release)
      end

      def call
        profiles.each { |profile| write(profile) }
      end

      private

      attr_reader :profiles, :release, :basedir, :basefilename, :all_fields

      def write(profile)
        rows = rows_for(profile)
          .map { |row| shorten(row) }
        return if rows.empty?

        to_csv(profile, rows)
      end

      def rows_for(profile)
        all_fields.select do |row|
          row["profile"] == profile &&
            row["record_type"] == "collectionobject" &&
            subject_field?(row)
        end
      end

      def subject_field?(row)
        row["ui_path"].start_with?("Content", "Associations")
      end

      def shorten(row)
        ["ui_info_group", "ui_path", "ui_field_label", "data_source",
          "repeats", "group_repeats"].each_with_object({}) do |hdr, h|
          h[hdr] = row[hdr]
        end
      end
    end
  end
end
