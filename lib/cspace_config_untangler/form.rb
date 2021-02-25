require 'cspace_config_untangler'

module CspaceConfigUntangler
  class Form
    attr_reader :rectype, :name, :config, :fields

    def initialize(rectypeobj, formname)
      @rectype = rectypeobj
      @name = formname
      @config = get_config
      @fields = []
      get_form_fields
      # This logic loop prevents failure for of publicart work due to an inconsistency in the config
      #  described at https://collectionspace.atlassian.net/browse/DRYD-882
      if @rectype.profile.name == 'publicart_2-0-1' && @rectype.name == 'work'
        @fields = @fields.reject{ |f| f.name == 'addressCounty' }
      end
    end

    private

    def get_config
      return @rectype.config['forms'][@name]['template']['props']
    end

    def get_form_fields
      CCU::FormProps.new(self, @config)
    end
  end #class Form

  class FormProps
    attr :form, :panel, :name, :ui_path, :ns, :ns_for_id, :is_panel, :is_ext, :is_measurement, :is_address, :is_contact, :parent

    def initialize(formobj, hash, parent = nil)
      @form = formobj
      @hash = hash
      @parent = parent

      
      @name = get_name
      @is_panel = @form.rectype.panels.include?(@name)
      @is_ext = @is_panel ? @form.rectype.profile.extensions.include?(@name) : false
      @is_measurement = is_measurement?
      @is_address = is_address?
      @is_contact = false
      @is_blob = false
      
      @panel = get_panel_id
      @ns = get_ns
      @ns_for_id = get_ns_for_id
      @ui_path = build_ui_path

      # we only want top-level panels to be treated as such in the human-readable CSVs
      @panel = @parent.panel if @is_panel && @parent

      if @ns == 'ns2:collectionspace_core'
        #skip
      elsif @hash.dig('children')
        # this catches a form field whose child field is not defined as a field
        if @ns == 'ns2:works_common' && @name == 'workDateGroup'
          @form.fields << CCU::FormField.new(self)
        else
          CCU::FormChildren.new(@form, self, @hash['children'])
        end
      elsif @name == 'contact' && @form.rectype.profile.extensions.include?(@name)
        @is_contact = true
        process_subrecord('contact', 'default')
      elsif @name == 'blob' && @form.rectype.profile.extensions.include?(@name)
        @is_blob = true
        #        process_subrecord('blob', 'upload')
        process_subrecord('blob', 'view')
      elsif @name.empty?
        profile = @form.rectype.profile.name
        rectype = @form.rectype.name
        CCU::LOG.warn("FORM STRUCTURE: EMPTY HASH: #{profile} - #{rectype} - #{@form.name} contains empty hash under #{@parent.ui_path}")
      elsif @name == 'relation-list-item'
        #skip for now
      else
        @form.fields << CCU::FormField.new(self)
      end
    end

    private

    def is_measurement?
      return true if @name == 'measuredPartGroupList'
      return true if @parent && @parent.is_measurement
      return false
    end

    def is_address?
      return true if @name == 'addrGroupList'
      return true if @parent && @parent.is_address
      return false
    end
    
    def process_subrecord(subrec, formname)
      @hash = @form.rectype.profile.config['recordTypes'][subrec]['forms'][formname]['template']['props']['children']['props']
      @is_panel = true
      @is_ext = true
      @panel = @form.rectype.profile.config.dig('recordTypes', subrec, 'messages', 'panel', 'info', 'id')
      @ns = @form.rectype.profile.config['recordTypes'][subrec]['fields']['document']['[config]']['view']['props']['defaultChildSubpath']
      @ui_path = build_ui_path

      if formname == 'upload'
        CCU::FormProps.new(@form, @hash, self)
      else
        CCU::FormChildren.new(@form, self, @hash['children'])
      end
    end

    def get_panel_id
      if @is_panel
        return "panel.#{@form.rectype.name}.#{@name}"
      elsif @parent
        return @parent.panel
      else
        return ''
      end
    end
    
    def get_name
      if @hash.dig('name')
        @name = @hash['name']
      else
        @name = ''
      end
    end
    
    def get_ns
      if @parent
        ns = @parent.ns
      else
        ns = @form.rectype.ns
      end

      ns = @hash.dig('subpath') ? @hash['subpath'] : ns
#      ns = "ext.#{@name}" if @is_ext
      
      return ns        
    end

    def get_ns_for_id
      ns = @parent.ns_for_id if @parent && @parent.ns_for_id.start_with?('ext.')
      ns = 'ext.dimension' if is_measurement?
      ns = 'ext.address' if is_address? && @is_contact == false
      ns = 'ext.accessionattributes' if @ns == 'ns2:collectionobjects_accessionattributes'
      ns = 'ext.accessionuse' if @ns == 'ns2:collectionobjects_accessionuse'
      ns = 'ext.fineart' if @ns == 'ns2:collectionobjects_fineart'
      ns = 'ext.commission' if @ns == 'ns2:acquisitions_commission'
      if @ns == 'ns2:collectionobjects_variablemedia'
        @name.start_with?('contentWork') ? ns = 'ext.contentWorks' : ns = 'ext.technicalSpecs'
      end
      if @ns == 'ns2:conditionchecks_variablemedia'
        ns = 'ext.technicalChanges'
      end
      if @ns == 'ns2:persons_publicart' || @ns == 'ns2:organizations_publicart'
        ns = 'ext.socialMedia' if @name.start_with?('socialMedia')
      end
      ns = 'ext.locality' if @name.start_with?('localityGroup')
      ns = @ns if ns.nil?
      return ns
    end


    def build_ui_path
      return [] if @name == 'document'
      return [] if @is_panel && !@parent
      path = @parent ? @parent.ui_path.clone : []

      if is_input_table
        path << @form.rectype.input_tables[@name]
      elsif is_panel
        path << @panel  
      elsif @hash.dig('children') && !@name.empty?
        path << "#{@ns.sub('ns2:', '')}.#{@name}"
      else
        # skip
      end
      return path
    end

    def is_input_table
      return true if @form.rectype.input_tables.keys.include?(@name) && @hash['children']
    end
  end

  class FormField
    include CCU::TrackAttributes
    attr_reader :profile, :rectype, :name, :ns, :ns_for_id, :panel, :ui_path, :id, :to_csv

    def initialize(propsobj)
      @form = propsobj.form

      @profile = @form.rectype.profile.name
      @rectype = @form.rectype.name
      @name = propsobj.name
      @panel = propsobj.panel
      @ns = propsobj.ns
      @ns_for_id = propsobj.ns_for_id
      @ui_path = propsobj.ui_path
      @id = "#{@ns_for_id.sub('ns2:', '')}.#{@name}"
      @to_csv = format_csv
      clean_up
    end

    def csv_header
      return %w[profile record_type panel ui_path field_id field_name]
    end

    def to_h
      attrs = self.attr_readers.map{ |e| '@' + e.to_s }.map{ |e| e.to_sym }
      h = {}
      attrs.each{ |a| h[a] = self.instance_variable_get(a) }
      h.delete(:@to_csv)
      return h
    end

    private

    def format_csv
      arr = [@profile, @rectype]
      if @ui_path
        path = @ui_path.clone
        arr << path.shift
        arr << path.compact.join(' > ')
      else
        arr << ''
        arr << ''
      end
      @id ? arr << @id : arr << ''
      @name ? arr << @name : arr << ''
      return arr
    end

    def clean_up
      @form = @form.name
    end

  end #class FormField
  

  class FormChildren

    def initialize(formobj, parentprops, data)
      @form = formobj
      @parent = parentprops
      @children = standardize_form_data(data)
      @children.each{ |child| CCU::FormProps.new(@form, child['props'], @parent) } unless @children.nil?
    end

    # if there is only one child, it gets created as a hash
    # if there are multiple children, they are an array of hashes
    # turns a single child into an array containing one hash
    def standardize_form_data(data)
      if data.is_a?(Hash)
        result = [data]
      elsif data.is_a?(Array)
        result = data
      end
      report_non_nil_and_missing_keys(result)
      return result
    end

    # form children have keys: key, ref, props, and _owner
    # I'm proceeding based on the assumption that I only care about props because
    #  the others are always nil
    # This logs any non-nil values for key, ref, or _owner so I can inspect
    def report_non_nil_and_missing_keys(data)
      data.each{ |h|
        %w[key ref _owner].each{ |k| check_key(h, k) }
      } unless data.nil?
    end

    def check_key(hash, key)
      if hash.has_key?(key)
        CCU::LOG.warn("FORM STRUCTURE: NON-NIL HASH KEY: #{profile} - #{rectype} - #{@form.name} #{@parent.ui_path.join(' / ')} #{key} has value: #{hash[key]}") unless hash[key].nil?
      else
        CCU::LOG.warn("FORM STRUCTURE: MISSING HASH KEY: #{profile} - #{rectype} - #{@form.name} #{@parent.ui_path.join(' / ')} missing #{key} key")
      end
    end
    
    
  end #class FormChildren
  
end #module
