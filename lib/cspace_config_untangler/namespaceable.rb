# frozen_string_literal: true

# Mix in module with logic for identifying namespace values
module CspaceConfigUntangler
  module Namespaceable
    NS_MATCHER = /^(?:ns2:|ext\.)/

    def namespace?(val) = val.is_a?(String) && val.match?(NS_MATCHER)
  end
end
