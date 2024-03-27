# frozen_string_literal: true

require "csv"

module CspaceConfigUntangler
  module Report
    class AuthorityVocabUse
      class << self
        def call(...)
          new(...).call
        end
      end

      # @param profiles [nil, String]
      # @param target [String] path to output file
      def initialize(profiles: nil, target: CCU::Report.auth_vocab_report_path)
        @profiles = CCU::Cli::Helpers::ProfileGetter.call(profiles)
          .map do |profile|
            CCU::Profile.new(
              profile: profile, structured_date_treatment: :collapse
            )
          end
        @target = target
      end

      def call
        data = profiles.map { |profile| authorities_data(profile) }
          .flatten
        to_csv(data)
      end

      private

      attr_reader :profiles, :target

      def authorities_data(profile)
        authfields = profile.fields
          .select { |field| field.authority_controlled? }
        profile.authorities.map { |auth| auth_data(profile, authfields, auth) }
      end

      def auth_data(profile, fields, auth)
        fields = get_controlled_fields(profile, fields, auth)
        {
          profile: profile.name,
          authority: auth.split("/").first,
          authority_vocab: auth,
          used_in_profile: fields.empty? ? "n" : "y",
          controlled_field_ct: fields.length,
          controlled_fields: fields.join("\n")
        }
      end

      def get_controlled_fields(profile, fields, auth)
        return [] if profile.unused_authority_vocabs.include?(auth)

        fields.select { |field| field.controlled_by?(auth) }
          .map { |field| build_output(field) }
          .sort
      end

      def build_output(field)
        base = "#{field.rectype.label}: #{field.label}"
        return base if field.ui_path.blank?

        "#{base} (#{field.ui_path.join(">")})"
      end

      def to_csv(data)
        headers = data.first.keys
        CSV.open(target, "w") do |csv|
          csv << headers
          data.each { |row| csv << row.values_at(*headers) }
        end
        puts "Wrote #{target}"
      end
    end
  end
end
