# frozen_string_literal: true

require "csv"

module CspaceConfigUntangler
  module Report
    class XpathDepthCheck
      class << self
        def call
          new.call
        end
      end

      def initialize
        @max = 4
        @allfields = CCU::Report.get_qa_table
        @target = File.join(
          CCU.data_reference_dir,
          "qa_xpath_depth_check_#{CCU.release}.csv"
        )
      end

      def call
        eligible_rows = get_eligible_rows
        if eligible_rows.empty?
          puts "No fields with xpath depth > #{max}"
        else
          write(eligible_rows)
        end
      end

      private

      attr_reader :max, :allfields, :target

      def get_eligible_rows
        allfields.select { |row|
          !row["xml_path"].blank? &&
            row["xml_path"].split(" > ").length > max
        }
      end

      def write(eligible_rows)
        headers = eligible_rows.first.headers
        CSV.open(target, "w") do |csv|
          csv << headers
          eligible_rows.each { |row| csv << row.values_at(*headers) }
        end

        puts "Wrote #{target}"
      end
    end
  end
end
