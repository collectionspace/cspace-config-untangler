require 'cspace_config_untangler'

module CspaceConfigUntangler
  class Profile
    attr_reader :name, :config, :authorities, :rectypes, :rectypes_all, :extensions, :option_lists, :vocabularies, :panels, :form_fields, :field_defs, :messages, :structured_date_treatment
    
    def initialize(profile:, rectypes: [], structured_date_treatment: :explode)
      @name = profile
      @config = JSON.parse(File.read("#{CCU::CONFIGDIR}/#{@name}.json"))
      @messages = {}
      @extensions = get_extensions
      @option_lists = get_option_lists
      @vocabularies = get_vocabularies
      @structured_date_treatment = structured_date_treatment
      @rectypes = [] #rectype objects to be processed/reported
      @rectypes_all = [] #all rectype names for profile
      get_rectypes(rectypes)
      @authorities = get_authorities
      @special_rectypes = []
      @panels = get_panels
      CCU::StructuredDateMessageGetter.new(self) if @structured_date_treatment == :explode
      get_field_defs
      apply_overrides
      get_form_fields
    end

    def extensions_for(rectype)
      exts = {}
      @extensions.map{ |e| CCU::Extension.new(self, e) }.each{ |ext|
        if ext.type == 'generic'
          exts[ext.name] = ext
        elsif ext.rectypes.include?(rectype)
          exts[ext.name] = ext
        end
      }
      return exts
    end

    def defined_fields_not_used
      form_field_lookup = form_fields_by_id
      arr = []
      self.field_defs.keys.each{ |fd|
        arr << fd unless form_field_lookup.has_key?(fd)
      }
      return arr
    end

    def fields
      @rectypes.map{ |rt| rt.fields }.flatten
    end

    def nonunique_fields
      h = {}
      @rectypes.each{ |rt|
        if rt.nonunique_fields.nil?
          h[rt.name] = []
        else
          h[rt.name] = rt.nonunique_fields
        end
      }
      return h
    end

    def basename
      @name.split('_')[0]
    end

    def version
      @name.split('_')[1]      
    end

    def special_rectypes
      arr = []
      rtnames = @rectypes.map(&:name)
      arr << 'objecthierarchy' if rtnames.include?('collectionobject')
      arr << 'authorityhierarchy' if rectypes_include_authorities
      arr << 'relationship' if rtnames.include?('collectionobject') || rectypes_include_procedures
      arr
    end

    def authority_types
      @rectypes_all.select{ |rt| @config['recordTypes'][rt]['serviceConfig']['serviceType'] == 'authority' }
        .map{ |rt| @config['recordTypes'][rt]['serviceConfig']['servicePath'] }
        .sort
    end

    def authority_subtypes
      ast = @rectypes_all.select{ |rt| @config['recordTypes'][rt]['serviceConfig']['serviceType'] == 'authority' }
        .map{ |rt| @config['recordTypes'][rt]['vocabularies'] }
        .map{ |vocabhash| vocabhash.map{ |vocab, h| h['serviceConfig']['servicePath'] } }
        .flatten      
        .reject{ |e| e == '_ALL_' }
        .map{ |refname| refname.match(/\((.*)\)/)[1] }
        .uniq
      ast.sort
    end

    def object_and_procedures
      op = @rectypes_all.select{ |rt| @config['recordTypes'][rt]['serviceConfig']['serviceType'] == 'procedure' }
        .map{ |rt| @config['recordTypes'][rt]['serviceConfig']['servicePath'] }
      op << 'collectionobjects'
      op.sort
    end

    private

    def get_field_defs
      fields = @rectypes.map{ |rt| rt.field_defs }
      fields << CCU::RecordType.new(self, 'blob').field_defs if @extensions.include?('blob')

      h = {}
      fields.flatten.each{ |f|
        if h.has_key?(f.id)
          h[f.id] << f
        else
          h[f.id] = [f]
        end
      }

      @field_defs = h
    end

    def get_form_fields
      fields = @rectypes.map{ |rt| rt.form_fields }
      @form_fields = fields.flatten
    end

    def form_fields_by_id
      h = {}
      @form_fields.each{ |ff| h[ff.id] = ff }
      return h
    end

    def get_panels
      panels = @rectypes.map{ |rt| rt.panels }
      panels << CCU::RecordType.new(self, 'contact').panels if @extensions.include?('contact')
      return panels.flatten.sort
    end
    
    def get_vocabularies
      config = CCU::SiteConfig.new(@name)
      doc = Nokogiri::XML(config.rest('/vocabularies?pgSz=0'))
      list = []
      doc.xpath('//shortIdentifier').each{ |e| list << e.text }
      return list.sort
    end
    
    def apply_overrides
      # This applies messages defined at the profile level
      o = @config.dig('messages')
      if o
        o.each{ |k, v|
          apply_field_override(k, v) if k.start_with?('field.')
          apply_panel_override(k, v) if k.start_with?('panel.')
        }
      end

      # This accounts for the fact that the livingplant extension ids don't use extension format
      #  in field definitions
      to_update = @messages.keys.select{ |e| e['field.conservation_livingplant'] }
      to_update.each{ |key|
        newkey = key.sub('field.conservation_livingplant', 'field.ext.livingplant')
        @messages[newkey] = @messages[key]
        @messages.delete(key)
      }
    end

    def apply_field_override(id, value)
      type = id.split('.').last
      rev_id = id.sub(".#{type}", '')
      
      if @messages.has_key?(rev_id)
        @messages[rev_id][type] = value
      else
        @messages[rev_id] = {type => value}
      end
    end

    def apply_panel_override(id, value)
      @messages[id] = {'name' => value, 'fullName' => value}
    end
    
    def get_rectypes(rectypes)
      remove = %w[account all authrole authority batch batchinvocation blob contact idgenerator object procedure relation report reportinvocation structureddates vocabulary]
      @rectypes_all = @config['recordTypes'].keys - remove

      # if no rectypes are given, process all of them
      # otherwise process only the ones passed in
      @rectypes = rectypes.empty? ? @config['recordTypes'].keys - remove : rectypes - remove
      @rectypes = @rectypes.select{ |rt| @rectypes_all.include?(rt) }
      @rectypes = @rectypes.map{ |rt| CCU::RecordType.new(self, rt) }
    end
    
    def get_extensions
      remove = %w[core authItem]
      ext = @config['extensions'].keys - remove
      %w[contact blob].each{ |subrec| ext << subrec if @config['recordTypes'].keys.include?(subrec) }
      return ext
    end

    def get_authorities
      authorities = []
      @rectypes_all.each{ |rt|
        c = @config['recordTypes'][rt]
        if c.dig('serviceConfig', 'serviceType') == 'authority'
          c['vocabularies'].keys.reject{ |e| e == 'all' }.each{ |subtype|
            authorities << "#{rt}/#{subtype}" 
          }
        else
          next
        end
      }
      return authorities.sort
    end
    
    def rectypes_include_authorities
      @rectypes.select{ |rt| rt.service_type == 'authority' }.empty? ? false : true
    end

    def rectypes_include_procedures
      @rectypes.select{ |rt| rt.service_type == 'procedure' }.empty? ? false : true
    end

    def get_option_lists
      if @config.dig('optionLists')
        return @config['optionLists'].keys.sort
      else
        return []
      end
    end
    
  end
end
