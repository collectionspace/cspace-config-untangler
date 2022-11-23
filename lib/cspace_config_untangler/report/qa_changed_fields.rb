# frozen_string_literal: true

require 'csv'

module CspaceConfigUntangler
  module Report
    class QaChangedFields

      class << self
        def call(...)
          self.new(...).call
        end
      end

      # @param release [String]
      # @param prev [String] previous release
      def initialize(release:, prev:)
        @release = get_table(release)
        @prev = get_table(prev)
        @target = File.join(
          CCU.data_reference_dir(release: release),
          "qa_all_fields_#{release}.csv"
        )
        @prev_lookup = get_lookup(@prev)
        @release_lookup = get_lookup(@release)
      end

      def call
        @new_fids = select_new_fids



        CSV.open(target, 'w') do |csv|
          csv << headers
          flat.each{ |row| csv << row.to_csv }
        end

        binding.pry

        puts "Wrote #{target}"
      end

      private

      attr_reader :release, :prev, :target, :prev_lookup, :release_lookup,
        :new_fids

      def changed?(row, lookup)
        id = row['fid']
        return false if new_fids.any?(id)

        true unless row.to_h == lookup[id]
      end

      def deversion(row)
        row['fid'] = row['fid'].sub(/_\d+(-\d+){2} /, ' ')
        row['profile'] = row['profile'].sub(/_\d+(-\d+){2}/, '')
        row
      end

      def get_lookup(table)
        table.map{ |row| [row['fid'], row.to_h] }
          .to_h
      end

      def get_table(release)
        vrelease = CCU::Validate.release(release)
        path = CCU.allfields_path(release: vrelease)

        CSV.parse(File.read(path), headers: true)
          .map{ |row| deversion(row) }
      end

      def select_changed_fids
        release.select{ |row| changed?(row, prev_lookup) }
      end

      def select_new_fids
        release.reject{ |row| lookup.key?(row['fid']) }
          .map{ |row| row['fid'] }
      end
    end
  end
end
