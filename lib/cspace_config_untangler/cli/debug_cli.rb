# frozen_string_literal: true

require_relative "helpers"

module CspaceConfigUntangler
  module Cli
    class DebugCli < Thor
      include CCU::Cli::Helpers

      desc "form_subpaths",
        "Get all form props subpath values used"
      option :rectype,
        desc: "Comma separated list (no spaces) of record types to include. "\
        "Defaults to all.",
        default: "all",
        aliases: "-r"
      option :mode,
        desc: "Whether to output just list of subpath values, or to "\
        "include occurrence counts",
        enum: %w[value count code],
        default: "value",
        type: :string,
        aliases: "-m"
      def form_subpaths
        props = get_profiles.map do |profile|
          p = CCU::Profile.new(profile:)
          p.rectypes
            .map(&:forms)
            .flatten
            .map(&:values)
            .flatten
            .reject(&:disabled?)
            .map { |form| form.send(:iterator).send(:allprops) }
            .flatten
        end.flatten
          .select { |prop| prop.config.key?("subpath") }

        case options[:mode]
        when "value"
          props.map { |prop| prop.config["subpath"] }
            .uniq
            .map { |val| val.is_a?(Array) ? val.inspect : val }
            .sort
            .each { |val| puts val }
        when "count"
          props.group_by { |prop| prop.config["subpath"] }
            .map { |subpath, arr| [subpath, arr.length] }
            .sort_by { |subarr| subarr[1] }
            .reverse
            .to_h
            .each { |val, ct| puts "#{ct}\t#{val}" }
        when "code"
          result = props.map { |prop| prop.config["subpath"] }
            .uniq
            .sort_by { |val| val.is_a?(Array) ? val.inspect : val }
          puts result.inspect
        end
      end

      desc "form_props_types",
        "Get all values of props/type used"
      option :rectype,
        desc: "Comma separated list (no spaces) of record types to include. "\
        "Defaults to all.",
        default: "all",
        aliases: "-r"
      def form_props_types
        props = get_profiles.map do |profile|
          p = CCU::Profile.new(profile:)
          p.rectypes
            .map(&:forms)
            .flatten
            .map(&:values)
            .flatten
            .reject(&:disabled?)
            .map { |form| form.send(:iterator).send(:allprops) }
            .flatten
        end.flatten
          .select { |prop| prop.config.key?("type") }

        result = props.group_by { |prop| prop.config["type"] }
          .map { |subpath, arr| [subpath, arr.length] }
          .sort_by { |subarr| subarr[1] }
          .reverse
          .to_h

        result.each { |val, ct| puts "#{ct}\t#{val}" }
      end

      desc "form_props_sigs",
        "Get all used props key signature patterns"
      option :keys, desc: "Key signature to find", type: :array,
        required: false, aliases: "-k"
      option :selector, desc: "CCU::Forms::Props method used to "\
        "select specific props.", aliases: "-s", type: :string, required: false
      option :rejector, desc: "CCU::Forms::Props method used to "\
        "reject specific props.", aliases: "-r", type: :string, required: false
      option :count, desc: "Whether to print count of props following pattern",
        aliases: "-c", type: :boolean, default: true, required: false
      option :example, desc: "Whether to print examples", aliases: "-e",
        type: :boolean, default: false, required: false
      option :maxex, desc: "Maximum number of examples to print", aliases: "-m",
        type: :numeric, default: 10, required: false
      option :rectype,
        desc: "Comma separated list (no spaces) of record types to include. "\
        "Defaults to all.",
        default: "all",
        aliases: "-r"
      def form_props_sigs
        all = get_profiles.map do |profile|
          p = CCU::Profile.new(profile:)
          p.rectypes
            .map(&:forms)
            .flatten
            .map(&:values)
            .flatten
            .reject(&:disabled?)
            .map { |form| form.send(:iterator).send(:allprops) }
            .flatten
        end.flatten

        by_sig = if options[:keys]
          all.select { |p| p.keys == options[:keys].sort }
        else
          all
        end
        selected = if options[:selector]
          meth = options[:selector].to_sym
          by_sig.select { |p| p.send(meth) }
        else
          by_sig
        end
        rejected = if options[:rejector]
          selected.reject { |p| p.send(options[:rejector].to_sym) }
        else
          selected
        end
        grouped = rejected.group_by { |prop| prop.keys }

        grouped.sort_by { |keys, props| props.length }
          .reverse_each do |keys, props|
          puts "#{props.length}\t#{keys.inspect}" if options[:count]
          if options[:example]
            props.first(options[:maxex]).each do |prop|
              puts prop
              puts prop.config
              puts "\n"
            end
            puts "\n\n"
          end
        end
      end

      desc "check_xpath_depth",
        "Reports fields with unusual xpath depth (i.e. not 0, 1, 2, 3, or 4)"
      option :rectype,
        desc: "Comma separated list (no spaces) of record types to include. "\
        "Defaults to all.", default: "all", aliases: "-r"
      def check_xpath_depth
        field_defs = []
        get_profiles.each do |profile|
          p = CCU::Profile.new(profile:)
          rts = if options[:rectype] == "all"
            p.rectypes.map { |rt| rt.name }
          else
            options[:rectype].split(",").map { |e| e.strip }
          end
          p.field_defs.each do |_id, arr|
            arr.each { |fd| field_defs << fd if rts.include?(fd.rectype) }
          end
        end

        known_depths = [0, 1, 2, 3, 4]
        odd_depths = field_defs.reject do |fd|
          known_depths.any?(fd.schema_path.length)
        end
        odd_depths.each { |fd| puts(fd.id) }
      end

      desc "write_field_defs", "Write file containing field definition data"
      option :rectype,
        desc: "Comma separated list (no spaces) of record types to include. "\
        "Defaults to all.", default: "all", aliases: "-r"
      option :format, desc: "Output format: csv or json", default: "csv",
        aliases: "-f"
      option :output, desc: "Path to output file",
        default: "data/field_definitions.csv", aliases: "-o"
      def write_field_defs
        field_defs = []
        get_profiles.each do |profile|
          p = CCU::Profile.new(profile:)
          rts = if options[:rectype] == "all"
            p.rectypes.map { |rt| rt.name }
          else
            options[:rectype].split(",").map { |e| e.strip }
          end
          p.field_defs.each do |_id, arr|
            arr.each { |fd| field_defs << fd if rts.include?(fd.rectype) }
          end
        end
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
      option :rectype,
        desc: "Comma separated list (no spaces) of record types to include. "\
        "Defaults to all.", default: "all", aliases: "-r"
      option :format, desc: "Output format: csv or json", default: "csv",
        aliases: "-f"
      option :output, desc: "Path to output file",
        default: "data/form_fields.csv", aliases: "-o"
      def write_form_fields
        form_fields = []
        get_profiles.each do |profile|
          p = CCU::Profile.new(profile:)
          rts = if options[:rectype] == "all"
            p.rectypes.map { |rt| rt.name }
          else
            options[:rectype].split(",").map { |e| e.strip }
          end
          p.form_fields.each do |ff|
            form_fields << ff if rts.include?(ff.rectype)
          end
        end

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
