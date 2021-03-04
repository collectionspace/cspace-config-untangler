require 'cspace_config_untangler'

module CspaceConfigUntangler
  class RecordType
    attr_reader :profile, :name, :id, :config, :ns, :panels, :input_tables,
      :forms, :nonunique_fields, :structured_date_treatment, :service_type,
      :subtypes, :record_search_field

    def initialize(profileobj, rectypename)
      @profile = profileobj
      @name = rectypename
      @id = "#{@profile.name}/#{@name}"
      @config = @profile.config['recordTypes'][@name]
      @ns = get_namespace
      @panels = get_panels
      @input_tables = get_input_tables
      @forms = get_forms
      @structured_date_treatment = @profile.structured_date_treatment
      @service_type = @config.dig('serviceConfig', 'serviceType')
      @subtypes = @service_type == 'authority' ? get_subtypes : []
    end

    def field_defs
      if @config.dig('fields', 'document')
        defs = FieldDefinitionParser.new(self, @config['fields']['document'])
        return defs.field_defs
      else
        CCU::LOG.warn("#{profile.name} - #{name} has no field def hash")
      end
    end

    def form_fields
      all = []
      @forms.each{ |formname, form|
        all << form.fields
      }
      all_combined = all.flatten.uniq{ |f| f.id }
      return all_combined
    end

    def fields
      fields = form_fields.map{ |ff| CCU::Field.new(self, ff) }
      fields = explode_structured_date_fields(fields) if @structured_date_treatment == :explode
      fields = fields.flatten
      fields << media_uri_field if @name == 'media'
      @nonunique_fields = get_nonunique_fields(fields)
      return fields
    end

    def explode_structured_date_fields(fields)
      sd_fields = fields.select{ |f| f.structured_date? }
      fields = fields - sd_fields
      sd_fields.each{ |f| fields << CCU::StructuredDateFieldMaker.new(f).fields(@profile) }
      fields
    end

    def get_nonunique_fields(fields)
      h = {}
      fields.each{ |f|
        path = [f.schema_path, f.name].flatten.join(' > ')
        if h.has_key?(path)
          h[path] << f
        else
          h[path] = [f]
        end
      }
      multi = h.select{ |path, farr| farr.length > 1 }
      return multi.keys
    end

    def mappings
      checkhash = {}
      mappings = fields.map{ |f| FieldMapper.new(field: f).mappings}.flatten
      # ensure unique datacolumn values for templates and mapper
      mappings.each do |mapping|
        if checkhash.key?(mapping.datacolumn)
          add = mapping.xpath.empty? ? mapping.namespace.split('_').last : mapping.xpath.last
          mapping.datacolumn = "#{add}_#{mapping.datacolumn}"
        else
          mapping.datacolumn = mapping.datacolumn
          checkhash[mapping.datacolumn] = nil
        end
      end
      mappings
    end

    def batch_mappings
      mappings = remove_unimportable_fields_from(self.mappings)
      mappings = faux_require_mappings(mappings)
      mappings = faux_require_profile_specific_mappings(mappings)
      mappings
    end

    def id_field
      case @service_type
      when 'object'
        id_field = 'objectNumber'
      when 'authority'
        id_field = 'shortIdentifier'
      when 'procedure'
        required_mappings = batch_mappings.select{ |m| m.required == 'y' }
        case required_mappings.length
        when 0
          id_field = 'potTagNumber' if @name == 'pottag'
        when 1
          id_field = required_mappings.first.fieldname
        else
          # osteology has 3 required fields, but only the ID is suitable for use here
          id_field = 'InventoryID' if @name == 'osteology'
          id_field = 'movementReferenceNumber' if @name == 'movement'
        end
      end
      id_field
    end

    def search_field
      case @service_type
      when 'authority'
        doc_name = @config.dig('serviceConfig', 'documentName').sub(/s$/, '')
        field = "#{doc_name}TermGroupList/0/termDisplayName"
      else
        field = id_field
      end
      field
    end
    
    private


    # sets up "faux-required" fields for record types that do not have any required fields
    #   some unique ID field is required for batch import/processing
    def faux_require_mappings(mappings)
      instructions = {
        'movement' => 'movementReferenceNumber'
      }
      return mappings unless instructions.key?(@name)

      mapping = get_field_mapping(mappings, instructions[@name])
      mapping.required = 'y' unless mapping.nil?
      mappings
    end
    
    def faux_require_profile_specific_mappings(mappings)
      instructions = {
        'botgarden' => {
          'loanout' => 'loanOutNumber',
          'objectexit' => 'exitNumber'
        }
      }
      profile = @profile.basename
      return mappings unless instructions.key?(profile)
      return mappings unless instructions[profile].key?(@name)

      mapping = get_field_mapping(mappings, instructions[profile][@name])
      mapping.required = 'y' unless mapping.nil?
      mappings
    end

    def get_field_mapping(mappings, fieldname)
      mappings.select{ |m| m.fieldname == fieldname }.first
    end
    
    # get rid of mappings for fields we do not want to import via the batch import tool
    def remove_unimportable_fields_from(mappings)
      instructions = {
        'collectionobject' => %w[computedCurrentLocation],
        'media' => %w[mediaFileURI]
      }
      return mappings unless instructions.key?(@name)

      instructions[@name].each do |fieldname|
        mappings = mappings.reject{ |m| m.fieldname == fieldname }
      end
      mappings
    end
    
    def get_subtypes
      result = []
      vocabs = @config.dig('vocabularies')
      vocabs.each do |keyword, config|
        next if keyword == 'all'
        name = config.dig('messages', 'name', 'defaultMessage')
        servicepath = config.dig('serviceConfig', 'servicePath')
        servicepath_name = servicepath.match(/\((.*)\)/)[1]
        result << { name: name, subtype: servicepath_name }
      end
      result
    end
    
    def media_uri_field
      field_hash = {
        name: 'mediaFileURI',
        ns: 'not-mapped',
        repeats: 'n',
        in_repeating_group: 'n/a',
        data_type: 'string',
        value_source: [],
        value_list: [],
        required: 'n'
      }
      CCU::ForcedField.new(self, field_hash)
    end

    def get_forms
      if @config.dig('forms') && @name != 'blob'
        h = {}
        @config['forms'].keys.reject{ |e| e == 'mini' }.each{ |e| h[e] = CCU::Form.new(self, e) }
        return h
      else
        return {}
      end
    end


    def get_input_tables
      if @config.dig('messages', 'inputTable')
        h = {}
        @config['messages']['inputTable'].each{ |name, hash|
          h[name] = hash['id']
          @profile.messages[hash['id']] = {'name' => hash['defaultMessage'], 'fullName' => hash['defaultMessage']} unless @profile.messages.has_key?(hash['id'])
        }
        return h
      else
        return {}
      end
    end
    
    def get_panels
      if @config.dig('messages', 'panel')
        arr = []
        
        @config['messages']['panel'].keys.each{ |panelname|
          arr << panelname
          
          msgs = @profile.messages
          id = @config['messages']['panel'][panelname]['id']
          label = @config['messages']['panel'][panelname]['defaultMessage']
          msgs[id] = {'name' => label, 'fullName' => label} 
        }
        return arr
      else
        return []
      end
    end
    
    def get_namespace
      docname = @config['serviceConfig']['documentName']
      return "ns2:#{docname}_common"
    end
  end
  
  class RecordTypes
    attr_reader :list
    attr_reader :profiles

    # profiles = array of profile name strings
    def initialize(profiles)
      @profiles = profiles
      all = {}
      @profiles.each{ |p|
        CCU::Profile.new(p).recordtypes.each{ |rectype| all[rectype] = '' }
      }
      @list = all.keys.sort
    end
  end

end
