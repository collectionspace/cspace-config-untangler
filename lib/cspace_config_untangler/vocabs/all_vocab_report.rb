# frozen_string_literal: true

module CspaceConfigUntangler
  module Vocabs
    # Reports on all term lists
    class AllVocabReport
      private attr_reader :profiles, :mode, :outpath, :headers

      class << self
        def run(...)
          new(...).run
        end
      end

      # @param profiles [Array<String>]
      # @param mode [:csv, :stdout]
      # @param outpath [String]
      def initialize(profiles:, mode:, outpath:)
        @profiles = profiles
        @mode = mode
        return unless mode == :csv

        @outpath = outpath
        @headers = CCU::Vocabs::Vocab::CSV_HEADERS
      end

      def run
        if result.empty?
          puts "No vocabularies"
          return
        end

        send(:"run_#{mode}")
      end

      private def result = @result ||= get_result

      private def get_result
        profiles.map do |profile|
          puts "Getting #{profile} vocabs..."
          CCU::Vocabs::Getter.call(profile)
        end.flatten
      end

      private def run_csv
        CSV.open(outpath, "w", headers: headers,
          write_headers: true) do |csv|
          result.each { |row| csv << row.to_csv }
        end
      end

      private def run_stdout
        result.group_by(&:profile)
          .each do |profile, vocabs|
          profile_stdout(profile, vocabs)
        end
      end

      private def profile_stdout(profile, vocabs)
        puts profile
        vocabs.each { |vocab| puts vocab.to_stdout(2) }
      end
    end
  end
end
