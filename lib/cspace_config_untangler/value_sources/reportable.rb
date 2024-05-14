# frozen_string_literal: true

module CspaceConfigUntangler
  module ValueSources
    # mixin module for shared output/report behavior
    module Reportable
      include Comparable

      def <=>(other)
        name <=> other.name
      end

      def fields_csv_label
        return if source_type == "na"
        return if name == "citation/shared"

        "#{source_type}: #{name}".sub("optionlist", "option list")
      end
    end
  end
end
