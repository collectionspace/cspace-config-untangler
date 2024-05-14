# frozen_string_literal: true

require "csv"

module CspaceConfigUntangler
  module Report
    class AllFieldsGenerator
      class << self
        def call(...)
          new(...).call
        end
      end

      # @param release [String]
      # @param datemode [:collapsed, :expanded]
      # @param outmode [:expert, :friendly]
      # @param target [nil, String] path to output file. Defaults to release
      #   allfields path for given datemode and outmode
      # @param profiles [nil, String]
      def initialize(release: CCU.release, datemode: :expanded,
        outmode: :expert, target: nil, profiles: "all")
        @release = release
        @datemode = CCU::Validate.date_mode(datemode.to_sym)
        @outmode = CCU::Validate.out_mode(outmode.to_sym)
        @profiles = CCU::Cli::Helpers::ProfileGetter.call(profiles)
        @target = target || CCU.allfields_path(
          release: release, datemode: datemode, outmode: outmode
        )
        @fields = []
      end

      def call
        profiles.each { |profile| get_fields(profile) }

        flat = fields.flatten
        headers = flat.first.csv_header(outmode)

        CSV.open(target, "w") do |csv|
          csv << headers
          flat.each { |row| csv << prepped(row) }
        end

        puts "Wrote #{target}"
      end

      private

      attr_reader :release, :datemode, :outmode, :profiles, :target, :fields

      def get_fields(profile)
        fields << CCU::Profile.new(profile: profile,
          rectypes: [],
          structured_date_treatment: datemode).fields
      end

      def prepped(row)
        case outmode
        when :expert then row.to_csv
        when :friendly then row.to_user_csv
        else fail "Unknown outmode"
        end
      end
    end
  end
end
