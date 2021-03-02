require 'cspace_config_untangler'

module CspaceConfigUntangler
  class AuthorityHierarchy
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
      'authorityhierarchy'
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
        object_name: 'Authority Hierarchy Relation',
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
          #subjectDocumentType: {},
          relationshipType: {},
          objectCsid: {},
          #objectDocumentType: {}
        }
      }
    end

    def mappings
      [
        {
          fieldname: 'termType',
          transforms: {},
          source_type: 'optionlist',
          source_name: 'fakeProfileAuthorityTypes',
          namespace: 'relations_common',
          xpath: [],
          data_type: 'string',
          repeats: 'n',
          in_repeating_group: 'n',
          opt_list_values: @profile.authority_types,
          datacolumn: 'term_type',
          required: 'y in template'
        },
        {
          fieldname: 'termSubType',
          transforms: {},
          source_type: 'optionlist',
          source_name: 'fakeProfileAuthoritySubtypes',
          namespace: 'relations_common',
          xpath: [],
          data_type: 'string',
          repeats: 'n',
          in_repeating_group: 'n',
          opt_list_values: @profile.authority_subtypes,
          datacolumn: 'term_subtype',
          required: 'y in template'
        },
        {
          fieldname: 'subjectCsid',
          transforms: { special: [:term_to_csid] },
          source_type: 'na',
          source_name: nil,
          namespace: 'relations_common',
          xpath: [],
          data_type: 'string',
          repeats: 'n',
          in_repeating_group: 'n',
          opt_list_values: [],
          datacolumn: 'narrower_term',
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
          fieldname: 'objectCsid',
          transforms: { special: [:term_to_csid] },
          source_type: 'na',
          source_name: nil,
          namespace: 'relations_common',
          xpath: [],
          data_type: 'string',
          repeats: 'n',
          in_repeating_group: 'n',
          opt_list_values: [],
          datacolumn: 'broader_term',
          required: 'y'
        },
      ]
    end
  end
end
