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
        res = source
          .select { |row| repeatable_multi_auth?(row) }
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

      def repeatable_multi_auth?(row) = multi_auth?(row) && repeatable?(row)

      def multi_auth?(row)
        type = row["data_source_type"]
        return false if type.blank?
        return false unless type.start_with?("authority")

        name = row["data_source_name"]
        return true if name.split(";").length > 2

        false
      end

      def repeatable?(row) = repeats?(row) || in_repeatable_group?(row)

      def in_repeatable_group?(row)
        val = row["group_repeats"]
        return false if val.blank?
        return true if ["as part of larger repeating group", "y"].any?(val)

        false
      end

      def repeats?(row)
        val = row["repeats"]
        return false if val.blank?
        return true if val == "y"

        false
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
