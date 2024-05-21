# frozen_string_literal: true

module CspaceConfigUntangler
  module FieldDefs
    class Iterator
      # @param manager [CCU::FieldDefs::ExtractionManager]
      def initialize(manager)
        @manager = manager
      end

      # @param name [String]
      # @param config [Hash]
      # @param mode [:namespace]
      def call(name:, config:, mode:)
        case mode
        when :namespace
          binding.pry
        end
      end
    end
  end
end
