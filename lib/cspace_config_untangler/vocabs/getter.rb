# frozen_string_literal: true

require_relative "vocab"

# @todo write tests
module CspaceConfigUntangler
  module Vocabs
    class Getter
      class << self
        def call(profilename)
          client = CCU.get_client(profilename)
          return [] unless client

          if client.is_a?(CollectionSpace::Client)
            configprofilename = CCU.profile_for(profilename)
            configprofile = CCU::Profile.new(profile: configprofilename)
            client.all("vocabularies")
              .map do |vocab|
                CCU::Vocabs::Vocab.new(vocab, profilename,
                  client, configprofile)
              end.to_a
          else
            puts client
            []
          end
        end
      end
    end
  end
end
