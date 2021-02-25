require 'cspace_config_untangler'

module CspaceConfigUntangler
  module CliHelpers
    def get_profiles
      all_profiles = [CCU::MAINPROFILE, CCU::PROFILES].flatten.uniq
      if options[:profiles].empty?
        return [CCU::MAINPROFILE]
      elsif options[:profiles] == 'all'
        return all_profiles
      else
        profiles = options[:profiles].split(',').map(&:strip)
        real_profiles = []
        profiles.each{ |p|
          if all_profiles.include?(p)
            real_profiles << p
          else
            puts "Unknown profile \"#{p}\" will be ignored..."
          end
        }
        return real_profiles.uniq
      end
    end
  end

  class TemplatesCli < Thor
    include CliHelpers

    desc 'write', 'Write batch import CSV templates for given (or all) record types in the given profiles.'
    long_desc <<-LONGDESC
    Using type = displayname creates templates assuming users want to enter human-readable name strings in the CSV. For fields populated from more than one authority or vocabulary, the template contains a separate column per term source.

    Using type = refname creates templates assuming users will enter CollectionSpace refnames in their CSV. One column is output per CollectionSpace field, regardless of how many authorities can be used to populate that field. 
  LONGDESC
    option :rectypes, desc: 'Comma-delimited (no spaces) list of record types to create templates for; if blank, will process all record types in profile', default: '', aliases: '-r'
    option :outputdir, desc: 'Path to output directory. File name will be: profile-rectype_template.csv', default:'data/templates', aliases: '-o'
    option :subdirs, desc: 'y/n. Whether to organize into subdirectories within given output directory by normalized profile name. Normalized profile name is the profile with version info/underscores removed.', default: 'n', aliases: '-s'
    option :type, desc: 'String. displayname, refname, or both.', default: 'displayname', aliases: '-t'
    def write
      rts = options[:rectypes].split(',').map(&:strip)
      
      unless %w[displayname refname both].include?(options[:type])
        puts "--type (-t) value must be one of the following: displayname, refname, both"
        exit
      end
      
      get_profiles.each do |profile|
        puts "Writing templates for #{profile}..."
        p = CCU::Profile.new(profile: profile, rectypes: rts, structured_date_treatment: :collapse)
        dir_path = options[:subdirs] == 'y' ? "#{options[:outputdir]}/#{p.basename}" : options[:outputdir]
        FileUtils.mkdir_p(dir_path)
        p.rectypes.each do |rt|
          puts "  ...#{rt.name}"
          types = options[:type] == 'both' ? %w[displayname refname] : [options[:type]]
          types.each do |type|
            path = type == 'refname' ? "#{dir_path}/refname" : dir_path
            FileUtils.mkdir_p(path) if type == 'refname'
            CsvTemplate.new(profile: p, rectype: rt, type: type).write(path)
          end
        end
        p.special_rectypes.each do |rt|
          puts "  ...#{rt}"
          classlkup = {
            'objecthierarchy'=>CCU::ObjectHierarchy,
            'authorityhierarchy'=>CCU::AuthorityHierarchy,
            'relationship'=>CCU::NonHierarchicalRelationship
          }
          rt = classlkup[rt].new(profile: p)
          types = options[:type] == 'both' ? %w[displayname refname] : [options[:type]]
          types.each do |type|
            path = type == 'refname' ? "#{dir_path}/refname" : dir_path
            FileUtils.mkdir_p(path) if type == 'refname'
            CsvTemplate.new(profile: p, rectype: rt, type: type).write(path)
          end
        end
      end
    end
  end # TemplatesCli class

  class DebugCli < Thor
    include CliHelpers

    desc 'write_field_defs', 'Write file containing field definition data'
    option :rectype, desc: 'Comma separated list (no spaces) of record types to include. Defaults to all.', default: 'all', aliases: '-r'
    option :format, desc: 'Output format: csv or json', default: 'csv', aliases: '-f'
    option :output, desc: 'Path to output file', default: 'data/field_definitions.csv', aliases: '-o'
    def write_field_defs
      field_defs = []
      get_profiles.each {|profile|
        p = CCU::Profile.new(profile: profile)
        if options[:rectype] == 'all'
          rts = p.rectypes.map{ |rt| rt.name }
        else
          rts = options[:rectype].split(',').map{ |e| e.strip }  
        end
        p.field_defs.each{ |id, arr|
          arr.each{ |fd| field_defs << fd if rts.include?(fd.rectype) }
        }
      }

      unless field_defs.empty?
        case options[:format]
        when 'csv'
          CSV.open(options[:output], 'wb'){ |csv|
            csv << field_defs[0].csv_header
            field_defs.each{ |fd| csv << fd.to_csv }
          }
        when 'json'
          File.open(options[:output], 'w'){ |file|
            file.write(JSON.pretty_generate(field_defs.map{ |fd| fd.to_h }))
          }
        else
          puts 'Format must be csv or json'
        end
      end
    end

    desc 'write_form_fields', 'Write file containing form field data'
    option :rectype, desc: 'Comma separated list (no spaces) of record types to include. Defaults to all.', default: 'all', aliases: '-r'
    option :format, desc: 'Output format: csv or json', default: 'csv', aliases: '-f'
    option :output, desc: 'Path to output file', default: 'data/form_fields.csv', aliases: '-o'
    def write_form_fields
      form_fields = []
      get_profiles.each {|profile|
        p = CCU::Profile.new(profile: profile)
        if options[:rectype] == 'all'
          rts = p.rectypes.map{ |rt| rt.name }
        else
          rts = options[:rectype].split(',').map{ |e| e.strip }  
        end
        p.form_fields.each{ |ff| form_fields << ff if rts.include?(ff.rectype) }
      }

      unless form_fields.empty?
        case options[:format]
        when 'csv'
          CSV.open(options[:output], 'wb'){ |csv|
            csv << form_fields[0].csv_header
            form_fields.each{ |ff| csv << ff.to_csv }
          }
        when 'json'
          File.open(options[:output], 'w'){ |file|
            file.write(JSON.pretty_generate(form_fields.map{ |ff| ff.to_h }))
          }
        else
          puts 'Format must be csv or json'
        end
      end
    end
  end # DebugCli class

  class MappersCli < Thor
    include CliHelpers

    desc 'manifest', 'Writes JSON manifest of RecordMappers, as used by cspace-batch-import'
    long_desc <<-LONGDESC
Usage:
\x5  ccu mappers manifest

Options:
\x5  -i, [--inputdir=INPUTDIR]    # Path to directory containing RecordMapper JSON files. Specify the path relative to #{CCU::MAPPER_DIR}
\x5  -o, [--output=OUTPUT]        # Path to output file
\x5                               # Default: /Users/kristina/code/cspace-config-untangler/data/mappers.json
\x5  -r, [--recursive=RECURSIVE]  # y/n. Whether to traverse the inputdir recursively
\x5                               # Default: y

Includes valid mappers in the given directory (recursively, as an option). Invalid mappers are excluded

The manifest is used by cspace-batch-import.

Assumes that all mappers will be found in `#{CCU::MAPPER_DIR}` (CCU::MAPPER_DIR) or subdirectories thereof. Base URI for raw files in this directory on Github in CCU::MAPPER_URI_BASE.

These constants can be changed in `lib/cspace_config_untangler.rb` if necessary.
LONGDESC
    option :inputdir, desc: "Path to directory containing RecordMapper JSON files. Specify the path relative to #{CCU::MAPPER_DIR}", default: '', aliases: '-i' 
    option :output, desc: 'Path to output file', default: "#{CCU::DATADIR}/mappers.json", aliases: '-o'
    option :recursive, desc: 'y/n. Whether to traverse the inputdir recursively', default: 'y', aliases: '-r'
    def manifest
      indir = "#{CCU::MAPPER_DIR}/#{options[:inputdir]}"
      unless Dir.exist?(indir)
        puts "Directory does not exist: #{indir}"
        exit
      end
      mapper_paths = Dir.glob("#{indir}/**/*.json")
      h = { 'mappers' => mapper_paths.map{ |path| CCU::ManifestEntry.new(path: path) }.map(&:to_h).compact }

      File.open(options[:output], "w") do |f|
        f.write(JSON.pretty_generate(h))
      end
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
          CspaceConfigUntangler::RecordMapper::RecordMapperWrapper.new(profile: p,
                                                                       rectype: rt,
                                                                       base_path: dir_path
                                                                      ).mappers.each do |mapper|
            mapper[:mapper].to_json(data: mapper[:mapper].hash, output: mapper[:path])
          end
        end
        p.special_rectypes.each do |rt|
          case rt
          when 'objecthierarchy'
            puts '  ...objecthierarchy'
            path = "#{dir_path}/#{p.name}_objecthierarchy.json"
            oh = CCU::ObjectHierarchy.new(profile: p)
            oh.to_json(data: oh.mapper, output: path)
          when 'authorityhierarchy'
            puts '  ...authorityhierarchy'
            path = "#{dir_path}/#{p.name}_authorityhierarchy.json"
            ah = CCU::AuthorityHierarchy.new(profile: p)
            ah.to_json(data: ah.mapper, output: path)
          when 'relationship'
            puts '  ...nonhierarchicalrelationship'
            path = "#{dir_path}/#{p.name}_nonhierarchicalrelationship.json"
            nhr = CCU::NonHierarchicalRelationship.new(profile: p)
            nhr.to_json(data: nhr.mapper, output: path)
          end
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
      puts "\n\nAll mappers validated. Any errors were reported above. Nothing above means all are valid!"
    end
  end # MappersCli class

  class FieldsCli < Thor
    include CliHelpers

    desc 'csv', 'Write CSV containing full field data'
    option :output, desc: 'Path to output file', default: 'data/fields.csv', aliases: '-o'
    option :rectypes, desc: 'Comma separated list (no spaces) of record types to include. Defaults to all.', default: 'all', aliases: '-r'
    option :structured_date,
      desc: 'explode: report all individual structured date fields; collapse: report the parent of individual structured date fields as the field',
      default: 'explode',
      aliases: '-sd'
    def csv
      unless %w[explode collapse].include?(options[:structured_date])
        puts '--structured_date parameter must be either "explode" or "collapse"'
        exit
      end
      rt = options[:rectypes] == 'all' ? [] : options[:rectypes].split(',')
      fs = []
      get_profiles.each {|profile|
        p = CCU::Profile.new(profile: profile, rectypes: rt, structured_date_treatment: options[:structured_date].to_sym)
        p.fields.each{ |f| fs << f }
      }
      unless fs.empty?
        CSV.open(options[:output], 'wb'){ |csv|
          csv << fs[0].csv_header
          fs.each{ |f| csv << f.to_csv }
        }
      end
    end

    desc 'nonunique', 'Print list of non-unique fields per profile'
    long_desc <<-LONGDESC
Uniqueness is determined by the full XML schema, i.e. the schema_path plus the field name.

The full schema_path should be unique within a record type. Non-unique fields are unexpected and the profile, record type, and schema path will be printed to the screen if any are found.
  LONGDESC
    def nonunique
      get_profiles.each {|profile|
        p = CCU::Profile.new(profile: profile)
        h = {}
        p.nonunique_fields.each{ |rt, fields| h[rt] = fields if fields.length > 0 }
        h.each{ |rt, fields| fields.each{ |f| puts "#{@name} - #{rt} - #{f}" } }
      }
    end
  end #FieldsCli class
  
  class ProfilesCli < Thor
    include CliHelpers
    desc 'all', 'Print the names of all known profiles'
    def all
      puts [CCU::MAINPROFILE, CCU::PROFILES].flatten.uniq.sort
    end

    desc 'check', 'Print the names of profiles that will be processed'
    def check
      profiles = get_profiles
      puts profiles
    end

    desc 'compare', 'Outputs a comparison of two profiles in CSV format'
    long_desc <<-LONGDESC
Requires two (and only two) profiles be specified with -p/--profile option:

> $ exe/ccu profiles compare -p core_6_1_0,anthro_4_1_2

The output CSV filename is generated by CCU.

The filename for the above will be: `compare_core_6_1_0_to_anthro_4_1_2.csv`.

You will find the csv file in the output directory you specified, or in the default directory shown above if you did not specify an output location. Examples of specifying custom output location below. Either form will work:

> $ exe/ccu profiles compare -p core_6_1_0,anthro_4_1_2 -o ~/files

> $ exe/ccu profiles compare -p core_6_1_0,anthro_4_1_2 -o /Users/you/files
LONGDESC
    option :output, desc: 'Path to directory in which to output file. Name of the file is hardcoded, using the names of the profiles.', default: CCU::DATADIR, aliases: '-o'
    def compare
      if options[:profiles] == 'all'
        profiles = get_profiles
      else
        profiles = options[:profiles].split(',').map{ |p| p.strip }
      end
      
      if profiles.length > 2
        puts "Can only compare two profiles at a time"
        exit
      elsif profiles.length == 1
        puts "Needs two profiles to compare"
        exit
      else
        CCU::ProfileComparison.new(profiles, options[:output]).write_csv
      end
    end

    desc 'by_extension', 'List all extensions used in profiles, and list which profile uses each'
    def by_extension
      exts = {}
      get_profiles.each{ |p|
        CCU::Profile.new(profile: p).extensions.each{ |ext|
          if exts.has_key?(ext)
            exts[ext] << p
          else
            exts[ext] = [p]
          end
        }
      }
      exts.keys.sort.each do |ext|
        puts ext
        exts[ext].each{ |p| puts "  #{p}" }
      end
    end

    desc 'main', 'Print the name of the main profile'
    def main
      puts CCU::MAINPROFILE
    end

    desc 'readable', 'Reformats (in place) JSON profile configs so that they are not one very long line. Non-destructive if run over JSON multiple times.'
    def readable
      get_profiles.each{ |p|
        puts "Reformatting #{p} config"
        profile = CCU::Profile.new(profile: p).config
        File.open("#{CCU::CONFIGDIR}/#{p}.json", 'w'){ |f|
          f.puts JSON.pretty_generate(profile)
        }
      }
    end
  end # ProfilesCli class

  class RecTypesCli < Thor
    include CliHelpers
    desc 'list', 'Lists record types in each profile'
    def list
      get_profiles.each{ |p|
        puts "\n#{p}:"
        puts CCU::Profile.new(profile: p).rectypes.map{ |e| "  #{e.name}" }
      }
    end
  end # RecTypesCli class
  
  class CommandLine < Thor
    include CliHelpers
    
    desc 'debug SUBCOMMAND', 'Commands useful for digging into why CCU is producing its results'
    subcommand 'debug', DebugCli

    desc 'fields SUBCOMMAND', 'Info/reports on fields in specified profiles/rectypes'
    subcommand 'fields', FieldsCli

    desc 'mappers SUBCOMMAND', 'Produce or work with JSON RecordMappers, as used by cspace-batch-import'
    subcommand 'mappers', MappersCli

    desc 'profiles SUBCOMMAND', 'Get info about and manipulate the profiles (i.e. CSpace application configs)'
    subcommand 'profiles', ProfilesCli

    desc 'rectypes SUBCOMMAND', 'Work with record types'
    subcommand 'rectypes', RecTypesCli

    desc 'templates SUBCOMMAND', 'Generate CSV templates for preparing data for cspace-batch-import'
    subcommand 'templates', TemplatesCli

    class_option :profiles,
      desc: 'Comma-separated list (NO SPACES) of non-main profiles you want to process. If not set, will run main profile only. If "all", will run all known profiles.',
      type: 'string',
      default: CCU::MAINPROFILE,
      aliases: '-p'

    desc 'test', 'temporary stuff for expediency'
    def test
      profile = 'botgarden_1_0_0'
      rt = 'collectionobject'
      rm = RecordMapping.new(profile: profile, rectype: rt)
    end

  end #class Thor::CommandLine
end #module
