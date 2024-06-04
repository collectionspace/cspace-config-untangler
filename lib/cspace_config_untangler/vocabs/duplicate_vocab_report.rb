# frozen_string_literal: true

module CspaceConfigUntangler
  module Vocabs
    # Reports on duplicate term lists
    class DuplicateVocabReport
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
          puts "No duplicate vocabularies"
          return
        end

        send(:"run_#{mode}")
      end

      private def result = @result ||= get_result

      private def get_result
        profiles.map do |profile|
          puts "Checking #{profile} vocabs for duplicates..."
          [profile,
            CCU::Vocabs.duplicates(CCU::Vocabs::Getter.call(profile))]
        end.to_h
          .reject { |_profile, vocabs| vocabs.empty? }
      end

      private def run_csv
        CSV.open(outpath, "w", headers: headers, write_headers: true) do |csv|
          result.values
            .map(&:values)
            .flatten
            .map(&:to_csv)
            .each { |row| csv << row }
        end
      end

      private def run_stdout
        result.each do |profile, dupevocabs|
          profile_stdout(profile, dupevocabs)
        end
      end

      private def profile_stdout(profile, dupevocabs)
        puts profile
        dupevocabs.each { |_normname, vocabs| dupeset_stdout(vocabs) }
      end

      private def dupeset_stdout(vocabs)
        puts "  #{vocabs.first.display_name}"
        vocabs.sort_by { |vocab| vocab.updated }
          .each { |vocab| puts vocab.to_stdout(4) }
      end
    end
  end
end
