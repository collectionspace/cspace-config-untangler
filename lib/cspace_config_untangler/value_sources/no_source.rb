# frozen_string_literal: true

module CspaceConfigUntangler
  module ValueSources
    # nil value object representing no value source
    class NoSource < AbstractValueSource
      def initialize
        @type = "na"
        @source_type = type
        @name = type
        @subtype = type
      end
    end
  end
end
