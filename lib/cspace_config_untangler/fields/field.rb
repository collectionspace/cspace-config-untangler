# frozen_string_literal: true

require_relative "../field_map/field_mapper"
require_relative "../upgrade_warner"
require_relative "../value_sources"

module CspaceConfigUntangler
  module Fields
    # Merges fields configuration field definition information into forms field
    # information
    class Field
      attr_reader :name, :label, :ns, :ns_for_id, :panel, :ui_path, :id,
        :schema_path,
        :repeats, :in_repeating_group,
        :data_type, :value_sources, :value_list,
        :required, :status
      attr_accessor :profile, :rectype

      def initialize(rectype_obj, form_field)
        @rectype = rectype_obj
        @profile = @rectype.profile
        @name = form_field.name
        @ns = form_field.ns
        @ns_for_id = form_field.ns_for_id
        @panel = form_field.panel
        @id = form_field.id
        @label = lookup_field_label
        @ui_path = formatted_ui_path(form_field.ui_path)
        merge_field_defs(form_field)
        @fid = "#{@profile.name} #{rectype.name} #{@ns_for_id} #{@name}"
      end

      def ok? = status == :ok

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
        return true unless value_sources

        value_sources.length == 1 &&
          value_sources.first.name == "na"
      end

      def controlled?
        !freetext?
      end

      def authority_controlled?
        controlled? &&
          value_sources.any? { |src| src.source_type == "authority" }
      end

      def vocabulary_controlled?
        controlled? &&
          value_sources.any? { |src| src.source_type == "vocabulary" }
      end

      def optionlist_controlled?
        controlled? &&
          value_sources.any? { |src| src.source_type == "optionlist" }
      end

      # @param name [String]
      def controlled_by?(name)
        return false unless controlled?

        value_sources.map { |src| src.name }
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

      def friendly_label
        "#{rectype.name.upcase}: #{ui_path.join(" > ")} > #{label}"
      end

      private

      def field_def = @field_def ||= find_field_def

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
          data_source_type: nil,
          data_source_name: nil,
          option_list_values: nil
        }
        row[:xml_path] = @schema_path.join(" > ") if @schema_path
        set_value_sources_for_csv(row)
        row[:option_list_values] = @value_list.join(", ") if @value_list
        row
      end

      def friendly_csv_row
        row = {
          profile: @profile.name,
          record_type: @rectype.label,
          record_type_machine_name: @rectype.name,
          record_section: get_ui_info_group,
          path_to_field: get_ui_path,
          field: label,
          field_machine_name: @name,
          qualified_field_machine_name: "#{@ns}.#{@name}",
          importer_template_headers: FieldMapper.new(field: self).column_names,
          data_type: @data_type,
          required: @required,
          repeats: @repeats,
          group_repeats: @in_repeating_group,
          data_source_type: nil,
          data_source_name: nil,
          option_list_values: nil
        }
        set_value_sources_for_csv(row)
        row[:option_list_values] = @value_list.join(", ") if @value_list
        row
      end

      def set_value_sources_for_csv(row)
        return unless @value_sources

        %i[type name].each do |srcdata|
          meth = :"csv_#{srcdata}"
          target = :"data_source_#{srcdata}"
          row[target] = @value_sources.map(&meth).compact.uniq.join("; ")
        end
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
        if field_def
          if field_def.valsrctype == "authority" &&
              field_def.value_sources == [CCU::ValueSources::NoSource.new]
            controlled_by_missing_authority
            @status = :problem
          else
            merge_from_field_def(formfield)
          end
        else
          CCU.log.error("CANNOT MATCH FORM FIELD TO FIELD DEF: "\
                        "#{formfield.form.id} #{formfield.id} "\
                        "(#{__FILE__}, #{__LINE__})")
          @value_sources = [CCU::ValueSources::NoSource.new]
          @status = :problem
        end
      end

      def controlled_by_missing_authority
        # Don't log warnings about known and reported issues
        if profile.name.start_with?("materials") &&
            rectype.name == "citation" &&
            name == "relatedTerm"
          CCU.upgrade_warner.call(target_version: "next release",
            issue: "DRYD-1425")
        elsif profile.name.start_with?("materials") &&
            rectype.name == "collectionobject" &&
            name == "contentConcept"
          CCU.upgrade_warner.call(target_version: "next release",
            issue: "DRYD-1648")
        else
          CCU.log.warn(
            "DATA SOURCES: #{field_def.config.namespace_signature} - #{@id} - "\
              "Authority autocomplete field defined with no configured "\
              "source (#{__FILE__}, #{__LINE__})"
          )
        end
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

      def merge_from_field_def(formfield)
        @schema_path = field_def.schema_path
        @repeats = formfield.repeats || field_def.repeats
        @in_repeating_group = formfield.in_repeating_group ||
          field_def.in_repeating_group
        @data_type = field_def.data_type
        @value_sources = field_def.value_sources
        @value_list = field_def.value_list
        @required = field_def.required
        @status = :ok
      end

      def lookup_field_label
        msgs = profile.messages
        fieldid = "field.#{id}"
        from_msg = msgs.dig(fieldid, "fullName") || msgs.dig(fieldid, "name")
        return from_msg if from_msg

        altform = case id
        when "uoc_common.useDateHoursSpent"
          CCU.upgrade_warner.call(target_version: "next release",
            issue: "DRYD-1269")
          "field.uoc_common.hoursSpent"
        when "collectionobjects_common.compressionStandard"
          CCU.upgrade_warner.call(target_version: "next release",
            issue: "DRYD-1270")
          "field.collectionobjects_common.compressionstandard"
        end
        from_msg = msgs.dig(altform, "fullName") || msgs.dig(altform, "name")
        return from_msg if from_msg

        if id == "conservation_common.sampleReturned"
          CCU.upgrade_warner.call(
            target_version: "next release", issue: "DRYD-1271"
          )
          base = "field.conservation_common.sampleReturned"
          msgs["#{base}.fullName"] || msgs["#{base}.nadme"]
        elsif id.start_with?("conservation_livingplant")
          fixedval = id.sub(
            "conservation_livingplant", "ext.livingplant"
          )
          lookup_display_name(fixedval)
        else
          alt_fieldname_lookup(id)
        end
      end

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
                        "#{profile.name} #{rectype.name} #{id} "\
                                    "#{__FILE__}, #{__LINE__})")
          nil
        elsif msgs.length > 1
          CCU.log.error("FIELD MESSAGE LOOKUP: MULTIPLE MESSAGES: "\
                            "#{profile.name} #{rectype.name} #{id} "\
                                        "#{__FILE__}, #{__LINE__})")
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
