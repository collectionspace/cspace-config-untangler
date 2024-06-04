# frozen_string_literal: true

require_relative "vocab_item"

module CspaceConfigUntangler
  module Vocabs
    class ItemGetter
      class << self
        # @param vocab [CCU::Vocabs::Vocab]
        # @return [Array<CCU::Vocabs::VocabItem>]
        def call(vocab)
          client = vocab.client
          return [] unless client.is_a?(CollectionSpace::Client)

          client.all("vocabularies/#{vocab.csid}/items")
            .map { |term| CCU::Vocabs::VocabItem.new(vocab, term) }
        end
      end
    end
  end
end
