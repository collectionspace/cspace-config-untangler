# frozen_string_literal: true

module CspaceConfigUntangler
  # methods to make special/manually created relationship rectypes act
  #  as much as real rectypes as they need to
  module SpecialRectype
    def batch_mappings(context = :mapper)
      mappings
    end

    def mapper(style = "old")
      {
        config: styled_config(style),
        docstructure: docstructure,
        mappings: mappings
      }
    end

    def styled_config(style)
      return config if style == "old"

      config.merge({dataConfigType: "record type"})
    end
  end
end
