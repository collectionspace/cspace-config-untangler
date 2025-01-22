# frozen_string_literal: true

# rubocop:disable Layout/LineLength
require_relative "subcommand_base"

module CspaceConfigUntangler
  module Cli
    class Templates < SubcommandBase
      desc "write",
        "Write batch import CSV templates for given (or all) record types in "\
        "the given profiles."
      long_desc <<-LONGDESC
    Using type = displayname creates templates assuming users want to enter human-readable name strings in the CSV. For fields populated from more than one authority or vocabulary, the template contains a separate column per term source.

    Using type = refname creates templates assuming users will enter CollectionSpace refnames in their CSV. One column is output per CollectionSpace field, regardless of how many authorities can be used to populate that field.
      LONGDESC
      shared_options :profiles, :rectypes, :subdirs
      shared_option :output_dir, default: File.join(CCU.datadir, "templates")
      option :type, desc: "Template type(s) to output",
        type: :string,
        enum: %w[displayname refname both],
        default: "displayname",
        aliases: "-t"
      def write
        outdir = File.expand_path(options[:output_dir])
        FileUtils.mkdir_p(outdir) unless Dir.exist?(outdir)

        types = if options[:type] == "both"
          %w[displayname refname]
        else
          [options[:type]]
        end

        get_profiles.each do |profile|
          puts "Writing templates for #{profile}..."
          profile = CCU::Profile.new(profile: profile, rectypes: parse_rectypes,
            structured_date_treatment: :collapse)
          dir_path = if options[:subdirs]
            File.join(outdir, profile.basename)
          else
            outdir
          end
          FileUtils.mkdir_p(dir_path)

          write_templates(profile, dir_path, types)
        end
      end

      no_commands do
        def write_templates(profile, dir_path, types)
          rectypes = profile.rectypes + profile.special_rectypes
          rectypes.each do |rectype|
            puts "  ...#{rectype.name}"
            write_rectype_profiles(profile, rectype, dir_path, types)
          end
        end

        def write_rectype_profiles(profile, rectype, dir_path, types)
          types.each do |type|
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
