# frozen_string_literal: true

require 'csv'

module CspaceConfigUntangler
  module Report
    class StructuredDateFieldsGenerator

      class << self
        def call(...)
          self.new(...).call
        end
      end

      # @param release [String]
      # @param sourcefile [nil, String] path to custom allfields CSV
      def initialize(release:, sourcefile: nil)
        @release = release
        @source = sourcefile || CCU.allfields_path(release: release)
        @target = CCU::Report.structured_date_report_path
      end

      def call
        unless File.exist?(source)
          CCU::Report::AllFieldsGenerator.call(
            release: release,
            datemode: :collapsed
          )
        end

        res = CSV.read(source, headers: true)
          .select{ |row| row['data_type'] == 'structured date group' }
          .map{ |row| simplify(row) }

        headers = res.first.headers

        CSV.open(target, 'w') do |csv|
          csv << headers
          res.each{ |row| csv << row.values_at(*headers) }
        end

        puts "Wrote #{target}"
      end

      private

      attr_reader :release, :source, :target

      def simplify(row)
        row = CCU::Report.simplify_allfields(row)
        row.delete('data_type')
        row.delete('option_list_values')
        row.delete('required')
        row.delete('data_source')
        row
      end
    end
  end
end
