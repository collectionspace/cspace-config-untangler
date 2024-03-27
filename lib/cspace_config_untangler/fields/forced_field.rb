require_relative "field"

module CspaceConfigUntangler
  module Fields
    # Provides a way to force a field external to the configs into Untangler output
    # Initially used only to make CSV templates for Media record types include a mediaFileURI field
    # See the `media_uri_field` private method in record_type.rb for how to set up field_hash parameter.
    class ForcedField < Field
      def initialize(rectype_obj, field_hash)
        @rectype = rectype_obj
        @profile = @rectype.profile
        @name = field_hash[:name]
        @ns = field_hash[:ns]
        @ns_for_id = @ns
        @panel = ""
        @ui_path = []
        @id = "#{@ns}.#{@name}"
        @schema_path = []
        @repeats = field_hash[:repeats]
        @in_repeating_group = field_hash[:in_repeating_group]
        @data_type = field_hash[:data_type]
        @value_source = field_hash[:value_source]
        @value_list = field_hash[:value_list]
        @required = field_hash[:required]
        @fid = "#{@profile.name} #{rectype.name} #{@ns_for_id} #{@name}"
      end
    end
  end
end
