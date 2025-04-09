# frozen_string_literal: true

require "digest"

require_relative "subcommand_base"

module CspaceConfigUntangler
  module Cli
    class Mappers < SubcommandBase
      desc "digest", "Output digest of a given mapper. Mainly useful if you "\
        "manually update a mapper and need to add new digest to manifest."
      option(:inputpath,
        type: :string,
        desc: "Path to JSON mapper file for which to output digest",
        required: true,
        aliases: "-i")
      def digest
        path = File.expand_path(options[:inputpath])
        puts Digest::SHA256.hexdigest(File.read(path))
      end

      desc "manifest",
        "Writes JSON manifest of RecordMappers, as used by cspace-batch-import"
      long_desc <<~LONGDESC
        Includes valid mappers in the given directory (recursively, as an
        option). Invalid mappers are excluded

        The manifest is used by cspace-batch-import.

        The base URI for raw files in
        this directory on Github in CCU.mapper_uri_base: #{CCU.mapper_uri_base}

        These constants can be changed in `lib/cspace_config_untangler.rb` if
        necessary.
      LONGDESC
      shared_options :input_dir
      shared_option :output_path,
        default: File.join(CCU.datadir, "mapper_manifests", "manifest.json")
      option(:recursive,
        type: :boolean,
        desc: "Whether to traverse the inputdir recursively",
        default: true,
        aliases: "-r")
      option(:dev,
        type: :boolean,
        desc: "Whether to output a dev manifest",
        default: false,
        aliases: "-d")
      def manifest
        indir = Pathname.new(File.expand_path(options[:input_dir]))
        unless indir.exist?
          puts "Directory does not exist: #{indir}"
          exit
        end

        outdir = Pathname.new(File.expand_path(options[:output_path]))

        puts "Building manifest with options:"
        opts = {
          inputdir: indir,
          output: outdir,
          recursive: options[:recursive],
          type: "record type"
        }
        opts.each { |key, val| puts "  #{key}: #{val}" }
        puts "  dev: #{options[:dev]}"
        builder = if options[:dev]
          CCU::ManifestDev.new(**opts)
        else
          CCU::Manifest.new(**opts)
        end
        builder.build
      end

      desc "write",
        "Writes JSON serializations of RecordMappers for the given rectype(s) "\
        "for the given profiles."
      shared_options :profiles, :rectypes, :subdirs, :env
      shared_option :output_dir, default: CCU.mapperdir
      def write
        CCU.config.instance_env = options[:env]

        outpath = File.expand_path(options[:output_dir])
        get_profiles.each do |profile|
          puts "Writing mappers for #{profile}..."
          p = CCU::Profile.new(profile: profile, rectypes: parse_rectypes,
            structured_date_treatment: :collapse)
          dir_path = if options[:subdirs]
            File.join(outpath, p.basename)
          else
            outpath
          end
          FileUtils.mkdir_p(dir_path)
          p.rectypes.each do |rt|
            puts "  ...#{rt.name}"
            CspaceConfigUntangler::RecordMapper::Wrapper.new(profile: p,
              rectype: rt,
              base_path: dir_path).mappers.each do |mapper|
              mapper[:mapper].to_json(data: mapper[:mapper].hash,
                output: mapper[:path])
            end
          end

          p.special_rectypes.each do |rt|
            name = rt.name
            puts "  ...#{name}"
            path = "#{dir_path}/#{p.name}_#{name}.json"
            rt.to_json(data: rt.mapper, output: path)
          end
        end
      end

      desc "validate", "Prints to screen a validation report of the JSON "\
        "mappers in a directory"
      long_desc <<-LONGDESC
        The input directory given will be recursively traversed to find .json
        files. It is expected that all .json files in this directory structure
        will be RecordMappers.

        Currently the validation checks for:
          - expected top-level keys
          - a URI for every namespace defined for the Mapper
          - a namespace defined for every field mapping
      LONGDESC
      shared_options :input_dir
      def validate
        in_dir = File.expand_path(options[:input_dir])
        mapper_paths = Dir.glob(File.join(in_dir, "**", "*", "*.json"))

        mapper_paths.each do |path|
          validator = RecordMapper::Validator.new(path)
          validator.report
        end
        puts "\n\nValidation complete. Any errors were reported above. "\
          "Nothing above means all are valid!"
      end
    end
  end
end
