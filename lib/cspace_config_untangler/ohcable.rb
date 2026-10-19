# frozen_string_literal: true

# Mix in module with logic for dealing with non-standard patterns in OHC
#   custom profile
module CspaceConfigUntangler
  module Ohcable
    # Reported in DRYD-2245
    def ohc_skippable_form_field?(props)
      return false if props.config.key?("subpath")

      props.profile.name.start_with?("ohc") &&
        props.rectype.name == "collectionobject" &&
        props.name == "descriptionLevel"
    end
  end
end
