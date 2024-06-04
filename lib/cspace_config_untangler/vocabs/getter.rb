# frozen_string_literal: true

require_relative "../client_builder"
require_relative "vocab"

module CspaceConfigUntangler
  module Vocabs
    class Getter
      class << self
        def call(profilename)
          client = get_client(profilename)
          if client.is_a?(CollectionSpace::Client)
            configprofilename = CCU.profile_for(profilename)
            client.all("vocabularies")
              .map do |vocab|
                CCU::Vocabs::Vocab.new(vocab, profilename,
                  client, configprofilename)
              end.to_a
          else
            puts client
            []
          end
        end

        private def get_client(name)
          CCU::ClientBuilder.call(name)
        rescue RuntimeError => err
          "#{name}: #{err.message}"
        end
      end
    end
  end
end
