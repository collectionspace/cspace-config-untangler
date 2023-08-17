module CspaceConfigUntangler
  module Fields
    class Field
      attr_reader :name, :label, :ns, :ns_for_id, :panel, :ui_path, :id,
        :schema_path,
        :repeats, :in_repeating_group,
        :data_type, :value_source, :value_list,
        :required
      attr_accessor :profile, :rectype

      def initialize(rectype_obj, form_field)
        @rectype = rectype_obj
        @profile = @rectype.profile
        @name = form_field.name
        @ns = form_field.ns
        @ns_for_id = form_field.ns_for_id
        @panel = form_field.panel
        @ui_path = formatted_ui_path(form_field.ui_path)
        @id = form_field.id
        @label = lookup_display_name(@id)
        merge_field_defs
        fix_museum_records if id == "places_nagpra.museumRecords"
        @fid = "#{@profile.name} #{rectype.name} #{@ns_for_id} #{@name}"
      end

      def csv_header(mode=:expert)
        case mode
        when :expert then expert_csv_row.keys.map(&:to_s)
        when :friendly then friendly_csv_row.keys.map(&:to_s)
        else fail "Unknown mode"
        end
      end

      def structured_date?
        if @data_type == 'structured date group'
          return true
        else
          return false
        end
      end

      def freetext?
        return true unless value_source

        value_source.length == 1 &&
          value_source.first.name == "na"
      end

      def controlled?
        !freetext?
      end

      def authority_controlled?
        controlled? &&
          value_source.any?{ |src| src.source_type == "authority" }
      end

      def vocabulary_controlled?
        controlled? &&
          value_source.any?{ |src| src.source_type == "vocabulary" }
      end

      def optionlist_controlled?
        controlled? &&
          value_source.any?{ |src| src.source_type == "optionlist" }
      end

      # @param name [String]
      def controlled_by?(name)
        return false unless controlled?

        value_source.map{ |src| src.name }
          .include?(name)
      end

      def to_csv
        format_csv(expert_csv_row)
      end

      def to_user_csv
        format_csv(friendly_csv_row)
      end

      private

      def formatted_ui_path(orig)
        return [] unless orig
        return [] if orig.empty?

        orig.compact
          .map{ |segment| lookup_display_name(segment) }
          .compact
      end

      def expert_csv_row
        {
          fid: @fid,
          profile: @profile.name,
          record_type: @rectype.name,
          namespace: @ns,
          namespace_for_id: @ns_for_id,
          field_id: @id,
          ui_info_group: get_ui_info_group,
          ui_path: get_ui_path,
          ui_field_label: label,
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

      def friendly_csv_row
        {
          profile: @profile.name,
          record_type: @rectype.label,
          field: label,
          record_section: get_ui_info_group,
          path_to_field: get_ui_path,
          data_type: @data_type,
          required: @required,
          repeats: @repeats,
          group_repeats: @in_repeating_group,
          data_source: @value_source.map(&:fields_csv_label).compact.join('; '),
          option_list_values: @value_list.join(', '),
          record_type_machine_name: @rectype.name,
          field_machine_name: @name
        }
      end

      def format_csv(source)
        source.values
          .map{ |val| val.nil? ? "" : val }
      end

      def get_ui_info_group
        return if ui_path.empty?

        ui_path[0]
      end

      def get_ui_path
        return if ui_path.empty?

        ui_path[1..-1].join(" > ")
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
        return nil unless val
        return nil if val["not-mapped"]

        msgs = @profile.messages

        if val.start_with?('panel.')
          if msgs.dig(val, 'name')
            msgs[val]['name']
          else
            alt_panel_lookup(val)
          end
        elsif val.start_with?('inputTable.')
          msgs.dig(val, 'name') ? msgs[val]['name'] : val
        else
          fieldid = "field.#{val}"
          if msgs.dig(fieldid, 'fullName')
            msgs[fieldid]['fullName']
          elsif msgs.dig(fieldid, 'name')
            msgs[fieldid]['name']
          elsif val == "uoc_common.useDateHoursSpent"
            CCU.warn_on_upgrade(binding.source_location, "DRYD-1269")
            alt_fieldname_lookup(val.sub("useDateHoursSpent", "hoursSpent"))
          elsif val == "collectionobjects_common.compressionStandard"
            CCU.warn_on_upgrade(binding.source_location, "DRYD-1270")
            alt_fieldname_lookup(
              val.sub("compressionStandard", "compressionstandard")
            )
          elsif val == "conservation_common.sampleReturned"
            CCU.warn_on_upgrade(binding.source_location, "DRYD-1271")
            msgs["field.conservation_common.sampleReturned.nadme"]["fullName"] ||
              msgs["field.conservation_common.sampleReturned.nadme"]["name"]
          elsif val.start_with?("conservation_livingplant")
            fixedval = val.sub("conservation_livingplant", "ext.livingplant")
            lookup_display_name(fixedval)
          else
            alt_fieldname_lookup(val)
          end
        end
      end

      def alt_fieldname_lookup(val)
        fieldname = val.split(".").last
        msgs = profile.messages
          .select do |id, data|
            id.start_with?("field.") && id.end_with?(".#{fieldname}")
          end
        return nil if msgs.empty?
        return "multiple msg matches: #{val}" if msgs.length > 1

        msgdata = msgs.first[1]
        fullname = msgdata["fullName"]
        return fullname if fullname

        name = msgdata["name"]
        return name if name

        val
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

      def fix_museum_records
        CCU.warn_on_upgrade(binding.source_location, "DRYD-1274")
        @label = ui_path.pop
      end
    end
  end
end
