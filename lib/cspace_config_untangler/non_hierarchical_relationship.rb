require 'cspace_config_untangler'

module CspaceConfigUntangler
  class NonHierarchicalRelationship
    include JsonWritable
    include SpecialRectype
    def initialize(profile: )
      @profile = profile
    end
    
    def mapper
      {
        config: config,
        docstructure: docstructure,
        mappings: mappings
      }
    end

    def name
      'nonhierarchicalrelationship'
    end

    private
    
    def config
      {
        profile_basename: @profile.basename,
        version: @profile.version,
        recordtype: name,
        document_name: 'relations',
        service_name: 'Relations',
        service_path: 'relations',
        service_type: 'relation',
        object_name: 'Non-Hierarchy Relation',
        ns_uri: {
          relations_common: 'http://collectionspace.org/services/relation'
        },
        identifier_field: 'subjectCsid',
        search_field: 'term'
      }
    end

    def docstructure
      {
        relations_common: {
          subjectCsid: {},
          relationshipType: {},
          objectCsid: {},
        }
      }
    end

    def mappings
      [
        {
          fieldname: 'subjectType',
          transforms: {},
          source_type: 'optionlist',
          source_name: 'fakeProfileTypes',
          namespace: 'relations_common',
          xpath: [],
          data_type: 'string',
          repeats: 'n',
          in_repeating_group: 'n',
          opt_list_values: @profile.object_and_procedures,
          datacolumn: 'item1_type',
          required: 'y in template'
        },
        {
          fieldname: 'subjectCsid',
          transforms: { special: [:obj_to_csid] },
          source_type: 'na',
          source_name: nil,
          namespace: 'relations_common',
          xpath: [],
          data_type: 'string',
          repeats: 'n',
          in_repeating_group: 'n',
          opt_list_values: [],
          datacolumn: 'item1_id',
          required: 'y'
          },
        {
          fieldname: 'relationshipType',
          transforms: {},
          source_type: 'na',
          source_name: nil,
          namespace: 'relations_common',
          xpath: [],
          data_type: 'string',
          repeats: 'n',
          in_repeating_group: 'n',
          opt_list_values: [],
          datacolumn: 'relationshiptype',
          required: 'y',
          to_template: false
        },
        {
          fieldname: 'objectType',
          transforms: {},
          source_type: 'optionlist',
          source_name: 'fakeProfileTypes',
          namespace: 'relations_common',
          xpath: [],
          data_type: 'string',
          repeats: 'n',
          in_repeating_group: 'n',
          opt_list_values: @profile.object_and_procedures,
          datacolumn: 'item2_type',
          required: 'y in template'
        },
        {
          fieldname: 'objectCsid',
          transforms: { special: [:obj_to_csid] },
          source_type: 'na',
          source_name: nil,
          namespace: 'relations_common',
          xpath: [],
          data_type: 'string',
          repeats: 'n',
          in_repeating_group: 'n',
          opt_list_values: [],
          datacolumn: 'item2_id',
          required: 'y'
        }
      ]
    end
  end
end
