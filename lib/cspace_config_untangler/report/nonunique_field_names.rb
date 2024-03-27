# frozen_string_literal: true

require "csv"

module CspaceConfigUntangler
  module Report
    class NonuniqueFieldNames
      class << self
        def call(...)
          new(...).call
        end
      end

      # @param profiles [nil, String]
      # @param mode [:stdout, :release]
      def initialize(profiles: nil, mode: :stdout)
        @profiles = CCU::Cli::Helpers::ProfileGetter.call(profiles)
          .map do |profile|
            CCU::Profile.new(
              profile: profile, structured_date_treatment: :collapse
            )
          end
        @mode = mode
        @categorized = []
        @legacy = {
          "bonsai" => {
            "conservation" => %w[futureTreatment futureTreatmentDate]
          },
          "anthro" => {
            "collectionobject" => %w[fieldLocVerbatim sex reference]
          },
          "botgarden" => {
            "collectionobject" => ["reference"]
          }
        }
      end

      def call
        result = profiles.map { |p| [p, p.nonunique_field_names] }
          .to_h
          .reject { |profile, info| info.empty? }
        result.empty? ? output_empty : output(result)
      end

      private

      attr_reader :profiles, :mode, :categorized, :legacy

      def output_empty
        puts "No non-unique field names"
      end

      def output(result)
        categorize(result)
        if mode == :stdout
          categorized.group_by { |h| h[:status] }
            .each { |cat, grp| to_stdout(cat, grp) }
        else
          to_csv
        end
      end

      def categorize(result)
        result.each do |profile, rectypes|
          categorize_profile(profile, rectypes)
        end
      end

      def categorize_profile(profile, rectypes)
        rectypes.each do |rt, fields|
          categorize_rectype(profile, rt, fields)
        end
      end

      def categorize_rectype(profile, rt, fields)
        fields.each do |field, paths|
          categorize_field(profile, rt, field, paths)
        end
      end

      def categorize_field(profile, rt, field, paths)
        name = profile.name
        cleanprofile = name.match(/^[a-z]+/i).to_s
        h = {profile: name, rectype: rt, field: field, xpaths: paths}
        categorized << if legacy.dig(cleanprofile, rt)&.include?(field)
          h.merge({status: :known})
        else
          h.merge({status: :new})
        end
      end

      def to_stdout(cat, grp)
        puts "\n#{cat.upcase}"
        grp.each do |fieldinfo|
          puts "#{fieldinfo[:profile]} - #{fieldinfo[:rectype]} - "\
            "#{fieldinfo[:field]}"
          fieldinfo[:xpaths].each { |xp| puts "  #{xp}" }
        end
      end

      def to_csv
        dir = CCU.data_reference_dir(CCU.release)
        path = File.join(dir, "qa_nonunique_field_names.csv")
        headers = categorized.first.keys
        CSV.open(path, "w") do |csv|
          csv << headers
          categorized.each { |fieldinfo| csv << fieldinfo.values_at(*headers) }
        end
        puts "Wrote #{path}"
      end
    end
  end
end
