require_relative 'helpers'

module CspaceConfigUntangler
  module Cli
    class MappersCli < Thor
      include CCU::Cli::Helpers

      desc 'manifest', 'Writes JSON manifest of RecordMappers, as used by cspace-batch-import'
      long_desc <<~LONGDESC
Usage:
\x5  ccu mappers manifest

Options:
\x5  -i, [--inputdir=INPUTDIR]    # Path to directory containing RecordMapper JSON files. Specify the path relative to #{CCU.mapperdir}
\x5  -o, [--output=OUTPUT]        # Path to output file
\x5                               # Default: /Users/kristina/code/cspace-config-untangler/data/mappers.json
\x5  -r, [--recursive=RECURSIVE]  # y/n. Whether to traverse the inputdir recursively
\x5                               # Default: y

Includes valid mappers in the given directory (recursively, as an option). Invalid mappers are excluded

The manifest is used by cspace-batch-import.

Assumes that all mappers will be found in `#{CCU.mapperdir}` (CCU.mapperdir) or subdirectories thereof. Base URI for raw files in this directory on Github in CCU.mapper_uri_base: #{CCU.mapper_uri_base}

These constants can be changed in `lib/cspace_config_untangler.rb` if necessary.
LONGDESC
      option(:inputdir,
             type: :string,
             desc: "Path to directory containing RecordMapper JSON files. Specify the path relative to #{CCU.mapperdir}",
             default: '',
             aliases: '-i')
      option(:output,
             type: :string,
             desc: 'Path to output file',
             default: "#{CCU.datadir}/mappers.json",
             aliases: '-o')
      option(:recursive,
             type: :boolean,
             desc: 'Whether to traverse the inputdir recursively',
             default: true,
             aliases: '-r')
      option(:dev,
             type: :boolean,
             desc: 'Whether to output a dev manifest',
             default: false,
             aliases: '-d')

      def manifest
        indir = Pathname.new("#{CCU.mapperdir}/#{options[:inputdir]}")
        unless indir.exist?
          puts "Directory does not exist: #{indir}"
          exit
        end
        puts "Building manifest with options:"
        opts = {inputdir: indir, output: options[:output], recursive: options[:recursive]}
        opts.each{ |key, val| puts "  #{key}: #{val}" }
        puts "  dev: #{options[:dev]}"
        builder = options[:dev] ? CCU::ManifestDev.new(**opts) : CCU::Manifest.new(**opts)
        builder.build
      end

      desc 'write', 'Writes JSON serializations of RecordMappers for the given rectype(s) for the given profiles.'
      option :rectypes, desc: 'Comma-delimited (no spaces) list of record types to write mappers for. If blank, will process all record types in profile', default: '', aliases: '-r'
      option :outputdir, desc: 'Path to output directory. File name will be: profile-rectype.json', default: 'data/mappers', aliases: '-o'
      option :subdirs, desc: 'y/n. Whether to organize into subdirectories within given output directory by normalized profile name. Normalized profile name is the profile with version info/underscores removed.', default: 'n', aliases: '-s'
      def write
        rts = options[:rectypes].split(',').map(&:strip)
        get_profiles.each do |profile|
          puts "Writing mappers for #{profile}..."
          p = CCU::Profile.new(profile: profile, rectypes: rts, structured_date_treatment: :collapse)
          dir_path = options[:subdirs] == 'y' ? "#{options[:outputdir]}/#{p.basename}" : options[:outputdir]
          FileUtils.mkdir_p(dir_path)
          p.rectypes.each do |rt|
            puts "  ...#{rt.name}"
            CspaceConfigUntangler::RecordMapper::Wrapper.new(profile: p,
                                                             rectype: rt,
                                                             base_path: dir_path
                                                            ).mappers.each do |mapper|
              mapper[:mapper].to_json(data: mapper[:mapper].hash, output: mapper[:path])
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

      desc 'validate', 'Prints to screen a validation report of the JSON mappers in a directory'
      long_desc <<-LONGDESC
    The output directory given will be recursively traversed to find .json files. It is
      expected that all .json files in this directory structure will be RecordMappers.

    Currently the validation checks for:
      - expected top-level keys
      - a URI for every namespace defined for the Mapper
      - a namespace defined for every field mapping
  LONGDESC
      option :input, desc: 'Path to input directory containing JSON mappers. Will be traversed recursively', default: 'data/mappers', aliases: '-i'
    def validate
      mapper_paths = Dir.glob("#{options[:input]}/**/*.json")
      mapper_paths.each do |path|
        validator = RecordMapper::Validator.new(path)
        validator.report
      end
      puts "\n\nValidation complete. Any errors were reported above. Nothing above means all are valid!"
    end
    end
  end
end
