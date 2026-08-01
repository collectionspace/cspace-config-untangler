# frozen_string_literal: true

module CspaceConfigUntangler
  # methods to make special/manually created relationship rectypes act
  #  as much as real rectypes as they need to
  module SpecialRectype
    def batch_mappings(context = nil, format = nil)
      mappings
    end

    def mapper(style = :csvimporter)
      {
        config: styled_config(style),
        docstructure: docstructure,
        mappings: mappings
      }
    end

    def styled_config(style)
      return config if style == :csvimporter

      config.merge({
        dataConfigType: "record type",
        display_name: display_name
      })
    end
  end
end
