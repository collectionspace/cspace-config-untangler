# frozen_string_literal: true

require 'csv'

module CspaceConfigUntangler
  module Report
    class QaDeletedFields

      class << self
        def call(...)
          self.new(...).call
        end
      end

      # @param release [String]
      def initialize(release:)
        @release = CCU::Report.get_qa_table
        @prev = CCU::Report.get_qa_table(prev: true)
        @target = File.join(
          CCU.data_reference_dir(release),
          "qa_deleted_fields_#{release}.csv"
        )
        @new_fids = @release.map{ |row| row["fid"] }.flatten
        @headers = @release.first.headers
      end

      def call
        CSV.open(target, 'w') do |csv|
          csv << headers
          prev.select{ |row| deleted?(row) }
            .each{ |row| csv << row.values_at(*headers) }
        end

        puts "Wrote #{target}"
      end

      private

      attr_reader :release, :prev, :target, :prev_lookup, :release_lookup,
        :new_fids, :headers

      def deleted?(row)
        return false if new_fids.include?(row["fid"])

        true
      end
    end
  end
end
