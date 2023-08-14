# frozen_string_literal: true

require 'csv'

module CspaceConfigUntangler
  module Report
    class AllFieldsGenerator

      class << self
        def call(...)
          self.new(...).call
        end
      end

      # @param release [String]
      # @param datemode [:collapsed, :expanded]
      def initialize(release:, datemode: :expanded)
        @release = release
        @mode = CCU::Validate.date_mode(datemode.to_sym)
        @profiles = CCU::Cli::Helpers::ProfileGetter.call('all')
        @target = File.join(
          CCU.data_reference_dir(release),
          "all_fields_#{release}_dates_#{mode}.csv"
        )
        @fields = []
      end

      def call
        profiles.each{ |profile| get_fields(profile) }

        flat = fields.flatten
        headers = flat.first.csv_header

        CSV.open(target, 'w') do |csv|
          csv << headers
          flat.each{ |row| csv << row.to_csv }
        end

        puts "Wrote #{target}"
      end

      private

      attr_reader :release, :mode, :profiles, :target, :fields

      def get_fields(profile)
        fields << CCU::Profile.new(profile: profile,
                                   rectypes: [],
                                   structured_date_treatment: mode
                                  ).fields
      end
    end
  end
end
