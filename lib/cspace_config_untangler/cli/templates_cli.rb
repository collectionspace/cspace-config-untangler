# frozen_string_literal: true

# rubocop:disable Layout/LineLength
require_relative "helpers"

module CspaceConfigUntangler
  module Cli
    class TemplatesCli < Thor
      include CCU::Cli::Helpers

      desc "write",
        "Write batch import CSV templates for given (or all) record types in the given profiles."
      long_desc <<-LONGDESC
    Using type = displayname creates templates assuming users want to enter human-readable name strings in the CSV. For fields populated from more than one authority or vocabulary, the template contains a separate column per term source.

    Using type = refname creates templates assuming users will enter CollectionSpace refnames in their CSV. One column is output per CollectionSpace field, regardless of how many authorities can be used to populate that field.
      LONGDESC
      option :outputdir,
        desc: "Path to output directory. File name will be: profile-rectype_template.csv", default: "data/templates", aliases: "-o"
      option :subdirs,
        desc: "y/n. Whether to organize into subdirectories within given output directory by normalized profile name. Normalized profile name is the profile with version info/underscores removed.", default: "n", aliases: "-s"
      option :type, desc: "String. displayname, refname, or both.",
        default: "displayname", aliases: "-t"
      def write
        unless %w[displayname refname both].include?(options[:type])
          puts "--type (-t) value must be one of the following: displayname, refname, both"
          exit
        end

        @subdirs = options[:subdirs] == "y"
        @outdir = options[:outputdir]
        @types = (options[:type] == "both") ? %w[displayname
          refname] : [options[:type]]

        get_profiles.each do |profile|
          puts "Writing templates for #{profile}..."
          profile = CCU::Profile.new(profile: profile, rectypes: parse_rectypes,
            structured_date_treatment: :collapse)
          dir_path = (options[:subdirs] == "y") ? "#{@outdir}/#{profile.basename}" : @outdir
          FileUtils.mkdir_p(dir_path)

          write_templates(profile, dir_path)
        end
      end

      no_commands do
        def write_templates(profile, dir_path)
          rectypes = profile.rectypes + profile.special_rectypes
          rectypes.each do |rectype|
            puts "  ...#{rectype.name}"
            write_rectype_profiles(profile, rectype, dir_path)
          end
        end

        def write_rectype_profiles(profile, rectype, dir_path)
          @types.each do |type|
            path = (type == "refname") ? "#{dir_path}/refname" : dir_path
            FileUtils.mkdir_p(path) if type == "refname"
            CsvTemplate.new(profile: profile, rectype: rectype,
              type: type).write(path)
          end
        end
      end
    end
  end
end
# rubocop:enable Layout/LineLength
