# frozen_string_literal: true

module CspaceConfigUntangler
  module Fields
    # Merges fields configuration field definition information into forms field
    # information
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
        @id = form_field.id
        @label = lookup_display_name(@id)
        @ui_path = formatted_ui_path(form_field.ui_path)
        merge_field_defs(form_field)
        @fid = "#{@profile.name} #{rectype.name} #{@ns_for_id} #{@name}"
      end

      def csv_header(mode = :expert)
        case mode
        when :expert then expert_csv_row.keys.map(&:to_s)
        when :friendly then friendly_csv_row.keys.map(&:to_s)
        else fail "Unknown mode"
        end
      end

      def structured_date?
        @data_type == "structured date group"
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
          value_source.any? { |src| src.source_type == "authority" }
      end

      def vocabulary_controlled?
        controlled? &&
          value_source.any? { |src| src.source_type == "vocabulary" }
      end

      def optionlist_controlled?
        controlled? &&
          value_source.any? { |src| src.source_type == "optionlist" }
      end

      # @param name [String]
      def controlled_by?(name)
        return false unless controlled?

        value_source.map { |src| src.name }
          .include?(name)
      end

      def to_csv
        format_csv(expert_csv_row)
      end

      def to_user_csv
        format_csv(friendly_csv_row)
      end

      def to_h
        expert_csv_row
      end

      private

      def formatted_ui_path(orig)
        return [] unless orig
        return [] if orig.empty?

        result = orig.compact
          .map { |segment| lookup_display_name(segment) }
          .compact
        return result if result.empty?
        return result unless result.last == label

        result.pop
        result
      end

      def expert_csv_row
        row = {
          fid: @fid,
          profile: @profile.name,
          record_type: @rectype.name,
          namespace: @ns,
          namespace_for_id: @ns_for_id,
          field_id: @id,
          ui_info_group: get_ui_info_group,
          ui_path: get_ui_path,
          ui_field_label: label,
          xml_path: nil,
          xml_field_name: @name,
          data_type: @data_type,
          required: @required,
          repeats: @repeats,
          group_repeats: @in_repeating_group,
          data_source: nil,
          option_list_values: nil
        }
        row[:xml_path] = @schema_path.join(" > ") if @schema_path
        if @value_source
          row[:data_source] = @value_source.map(&:fields_csv_label)
            .compact
            .join("; ")
        end
        row[:option_list_values] = @value_list.join(", ") if @value_list
        row
      end

      def friendly_csv_row
        row = {
          profile: @profile.name,
          record_type: @rectype.label,
          field: label,
          record_section: get_ui_info_group,
          path_to_field: get_ui_path,
          data_type: @data_type,
          required: @required,
          repeats: @repeats,
          group_repeats: @in_repeating_group,
          data_source: nil,
          option_list_values: nil,
          record_type_machine_name: @rectype.name,
          field_machine_name: @name
        }
        if @value_source
          row[:data_source] = @value_source.map(&:fields_csv_label)
            .compact
            .join("; ")
        end
        row[:option_list_values] = @value_list.join(", ") if @value_list
        row
      end

      def format_csv(source)
        source.values
          .map { |val| val.nil? ? "" : val }
      end

      def get_ui_info_group
        return if ui_path.empty?

        ui_path[0]
      end

      def get_ui_path
        return if ui_path.empty?

        ui_path[1..].join(" > ")
      end

      def merge_field_defs(formfield)
        fd = find_field_def
        merge_from_fd(formfield, fd) if fd
      end

      def find_field_def
        fd = @profile.field_defs.dig(@id)
        if fd.nil?
          find_field_def_alt
        elsif fd.length == 1
          fd.first
        else
          fd.find { |f| f.ns == @ns }
        end
      end

      def find_field_def_alt
        try_id = if @ns == "ns2:conservation_livingplant"
          @id.sub("ext.", "conservation_")
        else
          "#{@ns.sub("ns2:", "")}.#{@name}"
        end

        fd = @profile.field_defs.dig(try_id)
        if fd.nil?
          nil
        elsif fd.length == 1
          fd.first
        else
          fd.find { |f| f.ns == @ns }
        end
      end

      def merge_from_fd(formfield, fd)
        @schema_path = fd.schema_path
        @repeats = formfield.repeats || fd.repeats
        @in_repeating_group = formfield.in_repeating_group ||
          fd.in_repeating_group
        @data_type = fd.data_type
        @value_source = fd.value_source
        @value_list = fd.value_list
        @required = fd.required
      end

      # @todo Refactor this hideousness
      def lookup_display_name(val)
        return nil unless val
        return nil if val["not-mapped"]

        msgs = @profile.messages

        if val.start_with?("panel.")
          if msgs.dig(val, "name")
            msgs[val]["name"]
          else
            alt_panel_lookup(val)
          end
        elsif val.start_with?("inputTable.")
          msgs.dig(val, "name") ? msgs[val]["name"] : val
        else
          fieldid = "field.#{val}"
          if msgs.dig(fieldid, "fullName")
            msgs[fieldid]["fullName"]
          elsif msgs.dig(fieldid, "name")
            msgs[fieldid]["name"]
          elsif val == "uoc_common.useDateHoursSpent"
            CCU.upgrade_warner.call(
              target_version: "8_1",
              issue: "DRYD-1269"
            )
            alt_fieldname_lookup(val.sub("useDateHoursSpent", "hoursSpent"))
          elsif val == "collectionobjects_common.compressionStandard"
            CCU.upgrade_warner.call(
              target_version: "8_1",
              issue: "DRYD-1270"
            )
            alt_fieldname_lookup(
              val.sub("compressionStandard", "compressionstandard")
            )
          elsif val == "conservation_common.sampleReturned"
            CCU.upgrade_warner.call(
              target_version: "8_1",
              issue: "DRYD-1271"
            )
            base = "field.conservation_common.sampleReturned.nadme"
            msgs[base]["fullName"] || msgs[base]["name"]
          elsif val.start_with?("conservation_livingplant")
            fixedval = val.sub("conservation_livingplant", "ext.livingplant")
            lookup_display_name(fixedval)
          else
            alt_fieldname_lookup(val)
          end
        end
      end

      def alt_panel_lookup(val)
        trunc_lookup = {}
        @profile.messages.select do |id, h|
          id.start_with?("panel.")
        end.each do |id, h|
          name = id.split(".").last
          trunc_lookup[name] = h
        end
        trunc_val = val.split(".").last

        if trunc_lookup.dig(trunc_val, "name")
          trunc_lookup[trunc_val]["name"]
        else
          val
        end
      end

      def alt_fieldname_lookup(val)
        fieldname = val.split(".").last
        msgs = profile.messages
          .select do |id, data|
            id.start_with?("field.") && id.end_with?(".#{fieldname}")
          end

        if msgs.empty?
          CCU.log.error("FIELD MESSAGE LOOKUP: NO MESSAGE: "\
                        "#{profile.name} #{rectype.name} #{id}")
          nil
        elsif msgs.length > 1
          CCU.log.error("FIELD MESSAGE LOOKUP: MULTIPLE MESSAGES: "\
                        "#{profile.name} #{rectype.name} #{id}")
          "multiple msg matches: #{val}"
        else
          msgdata = msgs.first[1]
          fullname = msgdata["fullName"]
          return fullname if fullname

          name = msgdata["name"]
          return name if name

          val
        end
      end
    end
  end
end
