# frozen_string_literal: true

require 'csv'

module CspaceConfigUntangler
  module Report
    class QaAllFields

      class << self
        def call(...)
          self.new(...).call
        end
      end

      # @param release [String]
      # @param prev [String] previous release
      def initialize(release:, prev:)
        @release = release
        @newrel = CCU::Report.get_qa_table(release)
        @prev = CCU::Report.get_qa_table(prev)
        @target = File.join(
          CCU.data_reference_dir(release: release),
          "qa_all_fields_#{release}.csv"
        )
        @prev_lookup = @prev.map{ |row| row['fid'] }
      end

      def call
        newrel.map{ |row| augment(row) }
        headers = newrel.first.headers

        CSV.open(target, 'w') do |csv|
          csv << headers
          newrel.each{ |row| csv << row.values_at(*headers) }
        end

        puts "Wrote #{target}"
      end

      private

      attr_reader :release, :newrel, :prev, :target, :prev_lookup

      def augment(row)
        row['dumbfieldname'] = "#{row['record_type']} #{row['xml_field_name']}"
        row['new?'] = new?(row) ? 'y' : ''
        row
      end

      def new?(row)
        true unless prev_lookup.any?(row['fid'])
      end
    end
  end
end
