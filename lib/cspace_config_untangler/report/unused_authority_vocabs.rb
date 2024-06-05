# frozen_string_literal: true

require "csv"

module CspaceConfigUntangler
  module Report
    class UnusedAuthorityVocabs
      class << self
        def call(...)
          new(...).call
        end
      end

      def initialize
        @source = CCU::Report.auth_vocab_report_path
        unless File.exist?(source)
          CCU::Report::AuthorityVocabUse.call(profiles: "all")
        end
        @target = File.join(CCU.data_reference_dir,
          "qa_unused_authority_vocabs.csv")
      end

      def call
        rows = CSV.parse(File.read(source), headers: true)
          .select { |row| row["used_in_profile"] == "n" }
        if rows.empty?
          puts "No unused authority vocabularies"
        else
          to_csv(rows)
        end
      end

      private

      attr_reader :source, :target

      def to_csv(data)
        headers = data.first.headers
        CSV.open(target, "w") do |csv|
          csv << headers
          data.each { |row| csv << row.values_at(*headers) }
        end
        puts "Wrote #{target}"
      end
    end
  end
end
