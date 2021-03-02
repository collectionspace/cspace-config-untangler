require 'cspace_config_untangler'

module CspaceConfigUntangler
  class ObjectHierarchy
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
      'objecthierarchy'
    end

    private
    
    def object_parent_types
      @profile.config.dig('optionLists', 'objectParentTypes', 'values')
    end

    def config
      {
        profile_basename: @profile.basename,
        version: @profile.version,
        recordtype: name,
        document_name: 'relations',
        service_name: 'Relations',
        service_path: 'relations',
        service_type: 'relation',
        object_name: 'Object Hierarchy Relation',
        ns_uri: {
          relations_common: 'http://collectionspace.org/services/relation'
        },
        identifier_field: 'subjectCsid',
        search_field: 'objectNumber'
      }
    end

    def docstructure
      {
        relations_common: {
          subjectCsid: {},
          subjectDocumentType: {},
          relationshipType: {},
          relationshipMetaType: {},
          objectCsid: {},
          objectDocumentType: {}
        }
      }
    end

    def mappings
      [
        {
          fieldname: 'subjectCsid',
          transforms: { special: [:obj_num_to_csid] },
          source_type: 'na',
          source_name: nil,
          namespace: 'relations_common',
          xpath: [],
          data_type: 'string',
          repeats: 'n',
          in_repeating_group: 'n',
          opt_list_values: [],
          datacolumn: 'narrower_object_number',
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
          fieldname: 'relationshipMetaType',
          transforms: {},
          source_type: 'optionlist',
          source_name: 'objectParentTypes',
          namespace: 'relations_common',
          xpath: [],
          data_type: 'string',
          repeats: 'n',
          in_repeating_group: 'n',
          opt_list_values: object_parent_types,
          datacolumn: 'relationship_type',
          required: 'n'
        },
        {
          fieldname: 'objectCsid',
          transforms: { special: [:obj_num_to_csid] },
          source_type: 'na',
          source_name: nil,
          namespace: 'relations_common',
          xpath: [],
          data_type: 'string',
          repeats: 'n',
          in_repeating_group: 'n',
          opt_list_values: [],
          datacolumn: 'broader_object_number',
          required: 'y'
        }
      ]
    end
  end
end
