# frozen_string_literal: true

# require_relative "vocabs/vocab"

module CspaceConfigUntangler
  # Namespace for vocabulary definition and vocabulary item-related code
  module Vocabs
    module_function

    # @param vocabs [Array<CCU::Vocabs::Vocab>] for a given profile
    # @return [Hash{String=>Array<CCU::Vocabs::Vocab>}] key is display name of
    #   duplicate vocabularies return in value
    def duplicates(vocabs)
      vocabs.group_by { |vocab| vocab.display_name.downcase }
        .reject { |name, vocabs| vocabs.length == 1 }
    end
  end
end
