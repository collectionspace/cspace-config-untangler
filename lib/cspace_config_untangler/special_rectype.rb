require 'cspace_config_untangler'

module CspaceConfigUntangler
  # methods to make special/manually created relationship rectypes act as much as
  #  real rectypes as they need to
  module SpecialRectype
    def batch_mappings
      mappings
    end
  end
end
