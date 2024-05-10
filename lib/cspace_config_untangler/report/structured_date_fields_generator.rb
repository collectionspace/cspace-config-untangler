# frozen_string_literal: true

require "csv"

module CspaceConfigUntangler
  module Report
    class StructuredDateFieldsGenerator
      class << self
        def call(...)
          new(...).call
        end
      end

      # @param release [String]
      # @param sourcefile [nil, String] path to custom allfields CSV
      def initialize(release:, sourcefile: nil)
        @release = release
        @source = get_source(sourcefile)
        @target = CCU::Report.structured_date_report_path
      end

      def call
        res = source.select do |row|
                row["data_type"] == "structured date group"
              end
          .map { |row| simplify(row) }

        headers = res.first.headers

        CSV.open(target, "w") do |csv|
          csv << headers
          res.each { |row| csv << row.values_at(*headers) }
        end

        puts "Wrote #{target}"
      end

      private

      attr_reader :release, :source, :target

      def get_source(sourcefile)
        return CSV.parse(File.read(sourcefile), headers: true) if sourcefile

        CCU::Report.get_all_fields(release: release, outmode: :friendly)
      end

      def simplify(row)
        row.delete("data_type")
        row.delete("option_list_values")
        row.delete("required")
        row.delete("data_source")
        row
      end
    end
  end
end
