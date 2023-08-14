module CspaceConfigUntangler
  module Fields
    class Field
      attr_reader :name, :ns, :ns_for_id, :panel, :ui_path, :id,
        :schema_path,
        :repeats, :in_repeating_group,
        :data_type, :value_source, :value_list,
        :required
      attr_accessor :to_csv, :profile, :rectype

      def initialize(rectype_obj, form_field)
        @rectype = rectype_obj
        @profile = @rectype.profile
        @name = form_field.name
        @ns = form_field.ns
        @ns_for_id = form_field.ns_for_id
        @panel = form_field.panel
        @ui_path = form_field.ui_path
        @id = form_field.id
        merge_field_defs
        @fid = "#{@profile.name} #{rectype.name} #{@ns_for_id} #{@name}"
        @to_csv = format_csv
      end

      def csv_header
        csv_row.keys.map(&:to_s)
      end

      def structured_date?
        if @data_type == 'structured date group'
          return true
        else
          return false
        end
      end

      # returns copy of this Field object without all the profile and rectype data
      def clean
        c = self.dup
        c.profile = @profile.name
        c.rectype = @rectype.name
        c
      end

      private

      def csv_row
        {
          fid: @fid,
          profile: @profile.name,
          record_type: @rectype.name,
          namespace: @ns,
          namespace_for_id: @ns_for_id,
          field_id: @id,
          ui_info_group: get_ui_info_group,
          ui_path: get_ui_path,
          ui_field_label: lookup_display_name(@id),
          xml_path: @schema_path.join(' > '),
          xml_field_name: @name,
          data_type: @data_type,
          required: @required,
          repeats: @repeats,
          group_repeats: @in_repeating_group,
          data_source: @value_source.map(&:fields_csv_label).compact.join('; '),
          option_list_values: @value_list.join(', ')
        }
      end

      def format_csv
        csv_row.values
          .map{ |val| val.nil? ? "" : val }
      end

      def get_ui_info_group
        return "" unless @ui_path
        return "" if @ui_path.empty?

        lookup_display_name(@ui_path.compact.shift)
      end

      def get_ui_path
        return "" unless @ui_path
        return "" if @ui_path.empty?

        remaining = @ui_path.compact[1..-1]
        return "" unless remaining

        remaining.map{ |segment| lookup_display_name(segment) }
          .compact
          .join(" > ")
      end

      def merge_field_defs
        fd = find_field_def
        merge_from_fd(fd) if fd
      end

      def find_field_def
        fd = @profile.field_defs.dig(@id)
        if fd.nil?
          return find_field_def_alt
        elsif fd.length == 1
          return fd.first
        else
          return fd.select{ |f| f.ns == @ns }.first
        end
      end

      def find_field_def_alt
        if @ns == 'ns2:conservation_livingplant'
          try_id = @id.sub('ext.', 'conservation_')
        else
          try_id = "#{@ns.sub('ns2:', '')}.#{@name}"
        end

        fd = @profile.field_defs.dig(try_id)
        if fd.nil?
          return nil
        elsif fd.length == 1
          return fd.first
        else
          return fd.select{ |f| f.ns == @ns }.first
        end
      end

      def merge_from_fd(fd)
        @schema_path = fd.schema_path
        @repeats = fd.repeats
        @in_repeating_group = fd.in_repeating_group
        @data_type = fd.data_type
        @value_source = fd.value_source
        @value_list = fd.value_list
        @required = fd.required
      end

      def lookup_display_name(val)
        msgs = @profile.messages
        if val.start_with?('panel.')
          if msgs.dig(val, 'name')
            new = msgs[val]['name']
          else
            new = alt_panel_lookup(val)
          end
        elsif val.start_with?('inputTable.')
          msgs.dig(val, 'name') ? new = msgs[val]['name'] : new = val
        else
          val = "field.#{val}"
          if msgs.dig(val, 'fullName')
            new = msgs[val]['fullName']
          elsif msgs.dig(val, 'name')
            new = msgs[val]['name']
          elsif val.end_with?('Group')
            new = nil
          elsif val.end_with?('List')
            new = nil
          elsif val.end_with?('s')
            new = nil
          else
            new = val
          end
        end
        return new
      end

      def alt_panel_lookup(val)
        trunc_lookup = {}
        @profile.messages.select{ |id, h| id.start_with?('panel.') }.each{ |id, h|
          name = id.split('.').last
          trunc_lookup[name] = h
        }
        trunc_val = val.split('.').last
        
        if trunc_lookup.dig(trunc_val, 'name')
          new = trunc_lookup[trunc_val]['name']
        else
          new = val
        end
        return new
      end    
    end
  end
end
