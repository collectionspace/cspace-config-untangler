# standard library
require 'csv'
require 'fileutils'
require 'json'
require 'logger'
require 'pp'
require 'yaml'

# external gems
require 'bundler/setup'
require 'facets/kernel/blank'
require 'http'
require 'nokogiri'
require 'pry'
require 'thor'

module CspaceConfigUntangler
  ::CCU = CspaceConfigUntangler
  CCU.const_set('MAINPROFILE', 'core_6-1-0')
  CCU.const_set('DATADIR', '/Users/kristina/code/cspace-config-untangler/data')
  CCU.const_set('CONFIGDIR', "#{CCU::DATADIR}/configs")
  CCU.const_set('SITECONFIG', "#{CCU::DATADIR}/profile_config.yaml")
  config_file_names = Dir.new(CCU::CONFIGDIR).children
    .reject{ |e| e['readable'] }
    .reject{ |e| e == '.keep' }
    .map{ |fn| File.basename(fn).sub('.json', '') }
  CCU.const_set('PROFILES', config_file_names)
  File.delete('log.log') if File::exist?('log.log')
  CCU.const_set('LOG', Logger.new('log.log'))
  CCU.const_set('MAPPER_DIR', "#{CCU::DATADIR}/mappers")
  CCU.const_set('MAPPER_URI_BASE', 'https://raw.githubusercontent.com/collectionspace/cspace-config-untangler/master/data/mappers')


  autoload :VERSION, 'cspace_config_untangler/version'
  autoload :CommandLine, 'cspace_config_untangler/command_line'

  # mixins
  autoload :JsonWritable, 'cspace_config_untangler/json_writable'
  autoload :SpecialRectype, 'cspace_config_untangler/special_rectype'

  # canned mappers
  autoload :ObjectHierarchy, 'cspace_config_untangler/object_hierarchy'
  autoload :AuthorityHierarchy, 'cspace_config_untangler/authority_hierarchy'
  autoload :NonHierarchicalRelationship, 'cspace_config_untangler/non_hierarchical_relationship'

  # extracting field data from JSON config
  autoload :Field, 'cspace_config_untangler/field'
  autoload :FieldDefinitionParser, 'cspace_config_untangler/field_definition_parser'
  autoload :FieldDefinition, 'cspace_config_untangler/field_definition_parser'
  autoload :FieldVerifier, 'cspace_config_untangler/field_definition_parser'
  autoload :Form, 'cspace_config_untangler/form'
  autoload :FormProps, 'cspace_config_untangler/form'
  autoload :Profile, 'cspace_config_untangler/profile'
  autoload :ProfileComparison, 'cspace_config_untangler/profile_comparison'
  autoload :Extension, 'cspace_config_untangler/extensions'
  autoload :Extensions, 'cspace_config_untangler/extensions'
  autoload :ManifestEntry, 'cspace_config_untangler/manifest_entry'
  autoload :RecordTypes, 'cspace_config_untangler/record_types'
  autoload :RecordType, 'cspace_config_untangler/record_types'
  autoload :SiteConfig, 'cspace_config_untangler/site_config'
  autoload :StructuredDateMessageGetter, 'cspace_config_untangler/structured_date_message_getter'
  autoload :StructuredDateField, 'cspace_config_untangler/structured_date_field'
  autoload :StructuredDateFieldMaker, 'cspace_config_untangler/structured_date_field_maker'

  autoload :Template, 'cspace_config_untangler/template'
  autoload :CsvTemplate, 'cspace_config_untangler/template'

  
  # mapping CSV data to CSpace XML
  autoload :FieldMap, 'cspace_config_untangler/field_map'
  autoload :FieldMapper, 'cspace_config_untangler/field_map'
  autoload :FieldMapping, 'cspace_config_untangler/field_map'
  autoload :AuthorityConfigLookup, 'cspace_config_untangler/field_map'
  autoload :CsvMapper, 'cspace_config_untangler/csv_mapper'
  autoload :RecordMapper, 'cspace_config_untangler/record_mapper'
  autoload :RecordMapping, 'cspace_config_untangler/record_mapper'
  autoload :NamespaceUris, 'cspace_config_untangler/record_mapper'
  autoload :RowMapper, 'cspace_config_untangler/row_mapper'
  
  def self.safe_copy(hash)
    Marshal.load(Marshal.dump(hash))
  end

  module TrackAttributes
    def attr_readers
      self.class.instance_variable_get('@attr_readers')
    end

    def attr_accessors
      self.class.instance_variable_get('@attr_accessors')
    end

    def self.included(klass)
      klass.send :define_singleton_method, :attr_reader, ->(*params) do
        @attr_readers ||= []
        @attr_readers.concat params
        super(*params)
      end
      klass.send :define_singleton_method, :attr_accessor, ->(*params) do
        @attr_accessors ||= []
        @attr_accessors.concat params
        super(*params)
      end
    end
  end

end
