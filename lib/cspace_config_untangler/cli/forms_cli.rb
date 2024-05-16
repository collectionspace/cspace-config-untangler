# frozen_string_literal: true

require_relative "helpers"

module CspaceConfigUntangler
  module Cli
    class FormsCli < Thor
      include CCU::Cli::Helpers

      desc "disabled", "List disabled forms in given profiles/record types"
      def disabled
        get_profiles.map do |profile|
          CCU::Profile.new(profile: profile, rectypes: parse_rectypes)
            .rectypes
            .map { |rt| rt.forms.values }
        end
          .flatten
          .select { |form| form.disabled? }
          .each { |form| puts form.id }
      end

      desc "subpaths", "Get all form props subpath values used"
      option :mode,
        desc: "Whether to output just list of subpath values, or to "\
        "include occurrence counts",
        enum: %w[value count code],
        default: "value",
        type: :string,
        aliases: "-m"
      def subpaths
        props = get_profiles.map do |profile|
          p = CCU::Profile.new(profile: profile, rectypes: parse_rectypes)
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

      desc "props_types", "Get all values of props/type used"
      def props_types
        props = get_profiles.map do |profile|
          p = CCU::Profile.new(profile: profile, rectypes: parse_rectypes)
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

      desc "props_key_sigs", "Get all used props key signature patterns"
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
      def props_key_sigs
        all = get_profiles.map do |profile|
          p = CCU::Profile.new(profile: profile, rectypes: parse_rectypes)
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
    end
  end
end
