# frozen_string_literal: true

module CspaceConfigUntangler
  module ValueSources
    # Represents the authority vocabulary indication column paired with the
    #  term value in the Data Toolkit data format
    class DataToolkitAuthVocab < AbstractValueSource
      def initialize
        @type = "na"
        @source_type = "authority"
        @name = "authority vocabulary indication"
        @subtype = "na"
      end

      def configured? = true

      def csv_type = nil

      def csv_name = nil
    end
  end
end
