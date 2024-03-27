# frozen_string_literal: true

module CspaceConfigUntangler
  module Fields
    module ValueSources
      class TypeExtractor
        def self.call(field_hash)
          case field_hash.dig("view", "type")
          when "AutocompleteInput"
            "authority"
          when "OptionPickerInput"
            "option list"
          when "TermPickerInput"
            "vocabulary"
          else
            "no source"
          end
        end
      end
    end
  end
end
