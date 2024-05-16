# frozen_string_literal: true

require_relative "helpers"

module CspaceConfigUntangler
  module Cli
    class DebugCli < Thor
      include CCU::Cli::Helpers

      desc "check_xpath_depth",
        "Reports fields with unusual xpath depth (i.e. not 0, 1, 2, 3, or 4)"
      def check_xpath_depth
        field_defs = get_profiles.map do |profile|
          CCU::Profile.new(profile: profile, rectypes: parse_rectypes)
            .field_defs
            .values
        end.flatten

        known_depths = [0, 1, 2, 3, 4]
        odd_depths = field_defs.reject do |fd|
          known_depths.any?(fd.schema_path.length)
        end
        odd_depths.each { |fd| puts(fd.id) }
      end

      desc "write_field_defs", "Write file containing field definition data"
      option :format, desc: "Output format: csv or json", default: "csv",
        aliases: "-f"
      option :output, desc: "Path to output file",
        default: "data/field_definitions.csv", aliases: "-o"
      def write_field_defs
        field_defs = get_profiles.map do |profile|
          CCU::Profile.new(profile: profile, rectypes: parse_rectypes)
            .field_defs
            .values
        end.flatten

        return if field_defs.empty?

        case options[:format]
        when "csv"
          CSV.open(options[:output], "wb") do |csv|
            csv << field_defs[0].csv_header
            field_defs.each { |fd| csv << fd.to_csv }
          end
        when "json"
          File.write(options[:output], JSON.pretty_generate(
            field_defs.map { |fd| fd.to_h }
          ))
        else
          puts "Format must be csv or json"
        end
      end

      desc "write_form_fields", "Write file containing form field data"
      option :format, desc: "Output format: csv or json", default: "csv",
        aliases: "-f"
      option :output, desc: "Path to output file",
        default: "data/form_fields.csv", aliases: "-o"
      def write_form_fields
        form_fields = get_profiles.map do |profile|
          CCU::Profile.new(profile: profile, rectypes: parse_rectypes)
            .form_fields
        end.flatten

        return if form_fields.empty?

        case options[:format]
        when "csv"
          CSV.open(options[:output], "wb") do |csv|
            csv << form_fields[0].csv_header
            form_fields.each { |ff| csv << ff.to_csv }
          end
        when "json"
          File.write(options[:output], JSON.pretty_generate(
            form_fields.map { |ff| ff.to_h }
          ))
        else
          puts "Format must be csv or json"
        end
      end
    end
  end
end
