# frozen_string_literal: true

require "csv"

module CspaceConfigUntangler
  module Report
    class QaAllFields
      include BotgardenDroppable

      class << self
        def call(...)
          new(...).call
        end
      end

      # @param release [String]
      def initialize(release:)
        @release = release

        CCU.config.release = release
        @target = File.join(
          CCU.data_reference_dir,
          "qa_all_fields_#{release}.csv"
        )
      end

      def call
        augmented = new_release_allfields.map { |row| augment(row) }
        headers = augmented.first.headers

        CSV.open(target, "w") do |csv|
          csv << headers
          augmented.each { |row| csv << row.values_at(*headers) }
        end

        puts "Wrote #{target}"
      end

      private

      attr_reader :release, :target

      def new_release_allfields
        result = CCU::Report.get_qa_table
        return result unless drop_botgarden?

        drop_botgarden(result)
      end

      def prev_release_allfields
        result = CCU::Report.get_qa_table(prev: true)
        return result unless drop_botgarden?

        drop_botgarden(result)
      end

      def prev_lookup
        @prev_lookup ||= prev_release_allfields.map { |row| row["fid"] }
      end

      def augment(row)
        row["dumbfieldname"] = "#{row["record_type"]} #{row["xml_field_name"]}"
        row["new?"] = new?(row) ? "y" : ""
        row
      end

      def new?(row)
        true unless prev_lookup.any?(row["fid"])
      end
    end
  end
end
