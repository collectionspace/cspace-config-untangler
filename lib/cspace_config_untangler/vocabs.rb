# frozen_string_literal: true

# require_relative "vocabs/vocab"

module CspaceConfigUntangler
  # Namespace for vocabulary definition and vocabulary item-related code
  module Vocabs
    module_function

    # @param profiles [Array<String>] versionless profile basenames
    def from_profiles(profiles)
      profiles.map { |profile| CCU::Vocabs::Getter.call(profile) }
        .flatten
    end
  end
end
