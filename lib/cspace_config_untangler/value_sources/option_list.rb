# frozen_string_literal: true

module CspaceConfigUntangler
  module ValueSources
    # basic value object to represent an option list
    class OptionList < AbstractValueSource
      attr_reader :options

      def initialize(name, list_config)
        @name = name
        @options = list_config["values"].sort
        @source_type = "optionlist"
        @type = source_type
        @subtype = nil
      end

      def csv_type = "option list"
    end
  end
end
