# frozen_string_literal: true

require "csv"

module CspaceConfigUntangler
  module Report
    class MultiAuthRepeatableFieldsGenerator
      class << self
        def call(...)
          new(...).call
        end
      end

      # @param release [String]
      # @param sourcefile [nil, String] path to custom allfields CSV
      def initialize(release: CCU.release, sourcefile: nil)
        @release = release
        @source = get_source(sourcefile)
        @target = CCU::Report.multi_auth_report_path
      end

      def call
        res = source.select { |row| multi_auth?(row) && repeatable?(row) }
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

      def in_repeatable_group?(row)
        val = row["group_repeats"]
        return false if val.blank?

        true if ["as part of larger repeating group", "y"].any?(val)
      end

      def multi_auth?(row)
        val = row["data_source"]
        return false if val.blank?
        return false unless val["authority"]

        vals = val.split(";")
        true if vals.length > 1
      end

      def repeatable?(row)
        repeats?(row) || in_repeatable_group?(row)
      end

      def repeats?(row)
        val = row["repeats"]
        return false if val.blank?

        true if val == "y"
      end

      def simplify(row)
        row.delete("data_type")
        row.delete("option_list_values")
        row.delete("required")
        row
      end
    end
  end
end
