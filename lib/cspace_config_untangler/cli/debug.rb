# frozen_string_literal: true

require_relative "subcommand_base"

module CspaceConfigUntangler
  module Cli
    class Debug < CCU::Cli::SubcommandBase
      output_mode_settings = {
        enum: %w[csv json],
        default: "csv"
      }

      desc "check_xpath_depth",
        "Reports fields with unusual xpath depth (i.e. not 0, 1, 2, 3, or 4)"
      shared_options :profiles, :rectypes
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
      shared_options :profiles, :rectypes
      shared_option :output_mode, **output_mode_settings
      shared_option :output_path,
        default: File.join(CCU.datadir, "field_definitions.csv")
      def write_field_defs
        field_defs = get_profiles.map do |profile|
          CCU::Profile.new(profile: profile, rectypes: parse_rectypes)
            .field_defs
            .values
        end.flatten

        return if field_defs.empty?

        case options[:output_mode]
        when "csv"
          CSV.open(options[:output_path], "wb") do |csv|
            csv << field_defs[0].csv_header
            field_defs.each { |fd| csv << fd.to_csv }
          end
        when "json"
          File.write(options[:output_path], JSON.pretty_generate(
            field_defs.map { |fd| fd.to_h }
          ))
        end
      end

      desc "write_form_fields", "Write file containing form field data"
      shared_options :profiles, :rectypes
      shared_option :output_mode, **output_mode_settings
      shared_option :output_path,
        default: File.join(CCU.datadir, "form_fields.csv")
      def write_form_fields
        form_fields = get_profiles.map do |profile|
          CCU::Profile.new(profile: profile, rectypes: parse_rectypes)
            .form_fields
        end.flatten

        return if form_fields.empty?

        case options[:output_mode]
        when "csv"
          CSV.open(options[:output_path], "wb") do |csv|
            csv << form_fields[0].csv_header
            form_fields.each { |ff| csv << ff.to_csv }
          end
        when "json"
          File.write(options[:output_path], JSON.pretty_generate(
            form_fields.map { |ff| ff.to_h }
          ))
        end
      end
    end
  end
end
