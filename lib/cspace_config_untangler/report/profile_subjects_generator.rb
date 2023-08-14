# frozen_string_literal: true

require 'csv'

module CspaceConfigUntangler
  module Report
    class ProfileSubjectsGenerator

      class << self
        def call(...)
          self.new(...).call
        end
      end

      # @param profile [String]
      # @param release [String]
      def initialize(profile:, release: CCU.release)
        @mode = :collapsed
        @release = release
        @profile = CCU::Validate.profile(profile)
        @target = File.join(
          CCU.data_reference_dir(release),
          "#{profile}_subject_fields.csv"
        )
      end

      def call
        fields = get_fields(profile)
          .map{ |row| shorten(row) }
        return if fields.empty?

        headers = fields.first.keys

        CSV.open(target, 'w') do |csv|
          csv << headers
          fields.each{ |row| csv << row.values_at(*headers) }
        end

        puts "Wrote #{target}"
      end

      private

      attr_reader :release, :mode, :profile, :target

      def get_fields(profile)
        path = CCU.allfields_path
        CSV.parse(File.read(path), headers: true)
          .select{ |row| row["profile"] == profile &&
              row["record_type"] == "collectionobject" &&
              subject_field?(row) }
      end

      def subject_field?(row)
        row["ui_path"].start_with?("Content") ||
          row["ui_path"].start_with?("Associations")
      end

      def shorten(row)
        ["ui_info_group", "ui_path", "ui_field_label", "data_source",
         "repeats", "group_repeats"].inject({}) do |h, hdr|
          h[hdr] = row[hdr]; h
        end
      end
    end
  end
end
