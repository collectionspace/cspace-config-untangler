# frozen_string_literal: true

module CspaceConfigUntangler
  module Fields
    # Namespace for classes concerned with deriving field information
    #   from the rectype/fields section of JSON UI config
    #
    # This information gets combined with information in the
    #   rectype/forms/default/template section of the JSON UI config
    #   to create CCU::Fields::Field objects
    #
    # The information in a CCU::Fields::Definition::FieldDefinition include:
    # - namespace
    # - field_id
    # - field_name
    # - schema_path
    # - required
    # - repeats
    # - group_repeats
    # - data_type
    # - data_source
    # - option_list_values
    module Definition
      ::CCU::Fields::Def = CspaceConfigUntangler::Fields::Definition
    end
  end
end
