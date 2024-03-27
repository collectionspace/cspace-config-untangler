# frozen_string_literal: true

require "csv"

module CspaceConfigUntangler
  module Report
    class QaChangedFields
      class << self
        def call(...)
          new(...).call
        end
      end

      # @param release [String]
      def initialize(release:)
        @release = CCU::Report.get_qa_table
        @prev = CCU::Report.get_qa_table(prev: true)
        @target = File.join(
          CCU.data_reference_dir(release),
          "qa_changed_fields_#{release}.csv"
        )
        @prev_lookup = get_lookup(@prev)
        @release_lookup = get_lookup(@release)
        @headers = @release.first.headers.unshift("status")
      end

      def call
        @new_fids = select_new_fids

        CSV.open(target, "w") do |csv|
          csv << headers
          select_changed_fids.each { |row| write(row, csv) }
        end

        puts "Wrote #{target}"
      end

      private

      attr_reader :release, :prev, :target, :prev_lookup, :release_lookup,
        :headers, :new_fids

      def changed?(row, lookup)
        id = row["fid"]
        return false if new_fids.any?(id)

        true unless row.to_h == lookup[id]
      end

      def get_lookup(table)
        table.map { |row| [row["fid"], row.to_h] }
          .to_h
      end

      def select_changed_fids
        release.select { |row| changed?(row, prev_lookup) }
      end

      def select_new_fids
        release.reject { |row| prev_lookup.key?(row["fid"]) }
          .map { |row| row["fid"] }
      end

      def write(row, csv)
        newrow = row.to_h
          .merge("status" => "new")
        oldrow = prev_lookup[row["fid"]].to_h
          .merge("status" => "old")
        [newrow, oldrow].each do |r|
          csv << r.values_at(*headers)
        end
      end
    end
  end
end
