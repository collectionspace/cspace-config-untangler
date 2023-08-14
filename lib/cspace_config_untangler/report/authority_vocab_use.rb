# frozen_string_literal: true

require "csv"

module CspaceConfigUntangler
  module Report
    class AuthorityVocabUse

      class << self
        def call(...)
          self.new(...).call
        end
      end

      # @param profiles [nil, String]
      # @param target [String] path to output file
      def initialize(profiles: nil, target: CCU::Report.auth_vocab_report_path)
        @profiles = CCU::Cli::Helpers::ProfileGetter.call(profiles)
          .map do |profile| CCU::Profile.new(
            profile: profile, structured_date_treatment: :collapse)
          end
        @target = target
      end

      def call
        data = profiles.map{ |profile| authorities_data(profile) }
          .flatten
        to_csv(data)
      end

      private

      attr_reader :profiles, :target

      def authorities_data(profile)
        profile.authorities.map{ |auth| authority_data(profile, auth) }
      end

      def authority_data(profile, auth)
        fields = get_controlled_fields(profile, auth)
       {
          authority_vocab: auth,
          profile: profile.name,
          authority: auth.split("/").first,
          controlled_fields: fields.join("\n"),
          controlled_field_ct: fields.length,
          used_in_profile: fields.empty? ? "n" : "y"
        }
      end

      def get_controlled_fields(profile, auth)
        return [] if profile.unused_authority_vocabs.include?(auth)

        profile.fields
          .select{ |field| field.controlled_by?(auth) }
          .map{ |field| "#{field.rectype.name}/#{field.name} (#{field.ns})" }
          .sort
      end

      def to_csv(data)
        headers = data.first.keys
        CSV.open(target, "w") do |csv|
          csv << headers
          data.each{ |row| csv << row.values_at(*headers) }
        end
        puts "Wrote #{target}"
      end
    end
  end
end
