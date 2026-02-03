# frozen_string_literal: true

require_relative "../field_map/field_mapper"
require_relative "../messageable"
require_relative "../message_overrideable"
require_relative "../ucbable"
require_relative "../upgrade_warner"
require_relative "../value_sources"

module CspaceConfigUntangler
  module Fields
    # Merges fields configuration field definition information into forms field
    # information
    class Field
      include Messageable
      include MessageOverrideable
      include Ucbable

      attr_reader :name, :ns, :ns_for_id, :panel, :ui_path, :id,
        :schema_path,
        :repeats, :in_repeating_group,
        :data_type, :value_sources, :value_list,
        :required, :status
      attr_accessor :profile, :rectype

      def initialize(rectype_obj, form_field)
        @rectype = rectype_obj
        @profile = @rectype.profile
        message_setup
        @name = form_field.name
        @ns = form_field.ns
        @ns_for_id = form_field.ns_for_id
        @panel = form_field.panel
        @id = form_field.id
        @ui_path = form_field.ui_path
        merge_field_defs(form_field)
        @fid = "#{@profile.name} #{rectype.name} #{@ns_for_id} #{@name}"
      end

      def config = @config ||= get_config

      def label = @label ||= lookup_field_label

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

      def get_config
        return {} unless field_def

        field_def.config
      end

      def extract_messages
        return unless field_def

        msgs = field_def.config.hash.dig("[config]", "messages")
        return unless msgs

        add_messages(msgs)
      end

      def apply_overrides
        return unless field_def
        return if @messages.empty?

        overrides = profile.message_overrides
        return unless overrides

        overrides.select { |k, _v| @messages.any? { |m| m.id.match?(k) } }
          .each { |k, v| @messages.override(convert_to_config(k, v)) }
      end

      def formatted_ui_path = ui_path.map(&:message).join(" > ")

      def expert_csv_row
        row = {
          fid: @fid,
          profile: @profile.name,
          record_type: @rectype.name,
          namespace: @ns,
          namespace_for_id: @ns_for_id,
          field_id: @id,
          ui_info_group: panel&.message,
          ui_path: formatted_ui_path,
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
          record_section: panel&.message,
          path_to_field: formatted_ui_path,
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
        elsif ucb_controlled_by_missing_authority?
          nil
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
        msg = messages.find { |m| m.message_type == :fullName } ||
          messages.find { |m| m.message_type == :name }
        unless msg
          return "" if id.match?("not-mapped")

          CCU.log.error("FIELD MESSAGE LOOKUP: NO MESSAGE: "\
                "#{profile.name} #{rectype.name} #{id} "\
                "#{__FILE__}, #{__LINE__})")
          return ""
        end

        msg.message
      end

      def lookup_ui_path_segment_label(val)
        return unless val
        return if val["not-mapped"]

        msg = rectype.messages&.by_id(val)&.message

        unless msg
          CCU.log.error("UI PATH MESSAGE LOOKUP: NO MESSAGE: "\
                        "#{profile.name} #{rectype.name} #{val} "\
                        "#{__FILE__}, #{__LINE__})")
          return
        end

        msg
      end
    end
  end
end
