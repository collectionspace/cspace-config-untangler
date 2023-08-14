# frozen_string_literal: true

require 'csv'

module CspaceConfigUntangler
  module Report
    class ProfileFieldsGenerator

      class << self
        def call(...)
          self.new(...).call
        end
      end

      # @param release [String]
      # @param profile [String]
      def initialize(profile:, release: CCU.release)
        @mode = :collapsed
        @profile = CCU::Validate.profile(profile)
        @release = release
        @target = File.join(
          CCU.data_reference_dir(release),
          "#{profile}_fields.csv"
        )
      end

      def call
        fields = get_fields(profile)
        headers = fields.first.csv_header

        CSV.open(target, 'w') do |csv|
          csv << headers
          fields.each{ |row| csv << row.to_csv }
        end

        puts "Wrote #{target}"
      end

      private

      attr_reader :release, :mode, :profile, :target

      def get_fields(profile)
        CCU::Profile.new(profile: profile,
                         rectypes: [],
                         structured_date_treatment: mode
                        ).fields
      end
    end
  end
end
