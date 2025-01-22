# frozen_string_literal: true

require_relative "subcommand_base"

module CspaceConfigUntangler
  module Cli
    class Rectypes < SubcommandBase
      desc "list", "Lists record types in each profile"
      shared_options :profiles
      def list
        get_profiles.each do |p|
          puts "\n#{p}:"
          puts CCU::Profile.new(profile: p).rectypes.map { |e| "  #{e.name}" }
        end
      end

      desc "without_form", "List profiles/record types not having a form "\
        "with the given name"
      shared_options :profiles, :rectypes
      option :form, desc: "The formname (e.g. default, public, timebased)",
        required: true, type: :string, aliases: "-f"
      def without_form
        results = get_profiles.map do |profile|
          CCU::Profile.new(profile: profile, rectypes: parse_rectypes)
            .rectypes
            .reject { |rt| rt.has_form?(options[:form]) }
            .flatten
        end
        results.flatten!

        if results.empty?
          puts "All of the given record types have a `#{options[:form]}` form"
        else
          output_without_form_results(results)
        end
        exit(0)
      end

      no_commands do
        def output_without_form_results(results)
          results.group_by { |rt| rt.profile.name }
            .each do |profile, rt|
              puts profile
              rt.each { |rectype| puts "  #{rectype.name}" }
            end
        end
      end
    end
  end
end
