# frozen_string_literal: true

require_relative "../track_attributes"

module CspaceConfigUntangler
  module FieldMap
    # Represents mapping instructions for data from a specific value
    # source for a given field
    #
    # If the field has no refname-requiring value sources (i.e.
    #   authority or vocabulary sources), there is a 1-to-1
    #   correspondence between fields and FieldMappings
    #
    # If the field is populated from a vocabulary or from one or more
    #   authorities, a FieldMapping is created for of those sources.
    #   An additional "refname" FieldMapping is added to support batch
    #   ingest using CS refnames instead of authority terms.
    class FieldMapping
      ::FieldMapping = CspaceConfigUntangler::FieldMap::FieldMapping
      include CCU::TrackAttributes

      attr_reader :fieldname, :transforms, :source_type, :source_name,
        :namespace, :xpath, :data_type,
        :repeats, :in_repeating_group, :opt_list_values
      attr_accessor :datacolumn, :required
      def initialize(field:, datacolumn:, source_type:, source_name:,
        column_style:, transforms: {})
        @field = field
        @fieldname = field.name
        @namespace = field.ns.sub("ns2:", "")
        @xpath = field.schema_path
        @required = field.required || "n"
        @repeats = field.repeats
        @in_repeating_group = field.in_repeating_group || "n"
        @datacolumn = datacolumn
        @source_type = source_type
        @source_name = source_name
        @transforms = transforms
        @opt_list_values = derive_opt_list_values
        @data_type = @datacolumn["Refname"] ? "csrefname" : field.data_type
        @column_style = column_style
      end

      def to_h
        readable = attr_readers - [:field]
        accessible = attr_accessors
        attrs = readable + accessible

        ivs = attrs.flatten.map { |e| "@" + e.to_s }.map { |e| e.to_sym }
        h = {}
        attrs.each_with_index do |a, i|
          h[a.to_sym] = instance_variable_get(ivs[i])
        end
        h
      end

      private

      attr_reader :field

      def derive_opt_list_values
        if source_type == "authority vocabulary indication"
          field.value_sources
            .reject { |src| src.source_type == "refname" }
            .map { |src| src.name.split("/").map(&:capitalize).join("/") }
        else
          field.value_list
        end
      end
    end
  end
end
