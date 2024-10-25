# frozen_string_literal: true

require "csv"

module CspaceConfigUntangler
  module Report
    # This report is intended for use in client-facing mapping
    #   spreadsheets. All rows for the relevant profile can be pasted
    #   into a tab of the spreadsheet as a lookup data source.
    #
    # This allows the Data Migration Specialist to record record type
    #   and XML field name of mappings, add a concatenated field_id,
    #   and provide the UI labels without having to mess with joining
    #   the three fields in all fields tables that contain UI label info
    class UiLabelsForLookup
      class << self
        def call(...)
          new(...).call
        end
      end

      # @param release [String]
      # @param sourcepath [nil, String] path to custom expert allfields CSV,
      #   dates collapsed
      def initialize(release:, sourcepath: nil)
        @release = release
        @source = CCU::Report.get_source(path: sourcepath,
          default_method: :get_all_fields,
          default_opts: {release: release,
                         outmode: :expert})
        @target = File.join(CCU.data_reference_dir, "ui_labels_lookup.csv")
        @headers = %w[profile id label]
      end

      def call
        CSV.open(target, "w") do |outfile|
          outfile << headers

          source.each { |row| outfile << transform(row).values_at(*headers) }
        end

        puts "Wrote #{target}"
      end

      private

      attr_reader :release, :source, :target, :headers

      def transform(row)
        id = [row["record_type"], row["xml_field_name"]].join(".")
        label = [row["ui_info_group"], row["ui_path"],
          row["ui_field_label"]].reject { |x| x.blank? }
          .join(" > ")

        {"profile" => row["profile"], "id" => id, "label" => label}
      end
    end
  end
end
