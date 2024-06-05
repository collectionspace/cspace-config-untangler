# frozen_string_literal: true

module CspaceConfigUntangler
  module Vocabs
    # Reports on duplicate terms in a dynamic term list
    class DuplicateTermReport
      private attr_reader :profiles, :vocabs, :usage, :mode, :outpath

      class << self
        def run(...)
          new(...).run
        end
      end

      # @param profiles [Array<String>]
      # @param vocabs [Array<String>] short ids of vocabs to check
      # @param usage [Boolean]
      # @param mode [:csv, :stdout]
      # @param outpath [String]
      def initialize(profiles:, vocabs:, usage:, mode:, outpath:)
        @profiles = profiles
        @vocabs = vocabs
        @usage = usage
        @mode = mode
        return unless mode == :csv

        @outpath = outpath
      end

      def run
        if result.empty?
          puts "No duplicate vocabulary terms"
          return
        end

        send(:"run_#{mode}")
      end

      private def result = @result ||= get_result

      private def get_result
        profiles.map { |profile| [profile, profile_result(profile)] }
          .to_h
      end

      private def profile_result(profile)
        filtered_vocabs(profile).reject do |vocab|
          vocab.duplicate_terms.blank?
        end
      end

      private def filtered_vocabs(profile)
        all = CCU::Vocabs::Getter.call(profile)
        return all if vocabs == ["all"]

        all.select { |vocab| vocabs.include?(vocab.short_identifier) }
      end

      private def run_csv
        results = result.values
          .flatten
          .map { |term| term.duplicate_terms.values }
          .flatten
        headers = results.first.headers(usage: usage)
        if usage
          puts "Retrieving usage counts for duplicate terms..."
        end
        CSV.open(outpath, "w", headers: headers, write_headers: true) do |csv|
          results.each { |term| csv << term.to_csv(usage: usage) }
        end
      end

      private def run_stdout
        result.each do |profile, vocabs|
          profile_stdout(profile, vocabs)
        end
      end

      private def profile_stdout(profile, vocabs)
        puts profile
        vocabs.each { |vocab| vocab_stdout(vocab) }
      end

      private def vocab_stdout(vocab)
        puts vocab.to_stdout
        vocab.duplicate_terms.each do |_name, terms|
          termset_stdout(terms)
        end
      end

      private def termset_stdout(terms)
        puts "    #{terms.first.display_name}"
        terms.each { |term| puts term.to_stdout(usage: usage) }
      end
    end
  end
end
