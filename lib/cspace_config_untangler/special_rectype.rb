# frozen_string_literal: true

module CspaceConfigUntangler
  # methods to make special/manually created relationship rectypes act as much as
  #  real rectypes as they need to
  module SpecialRectype
    def batch_mappings(context = :mapper)
      mappings
    end
  end
end
