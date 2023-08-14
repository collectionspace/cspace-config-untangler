# frozen_string_literal: true

module CspaceConfigUntangler
  module ValueSources
    # basic value object to represent a vocabulary
    class Vocabulary < AbstractValueSource

      def initialize(vocabulary_source_string)
        @type = 'vocabulary'
        @name = vocabulary_source_string
        @subtype = name
        @source_type = type
      end
    end
  end
end
