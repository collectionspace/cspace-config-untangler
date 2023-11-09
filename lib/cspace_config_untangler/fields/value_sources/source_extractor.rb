# frozen_string_literal: true

module CspaceConfigUntangler
  module Fields
    module ValueSources
      class SourceExtractor
        def self.call(type, field_hash, profile)
          return [CCU::ValueSources::NoSource.new] if type == "no source"

          sources = field_hash.dig("view", "props", "source")

          case type
          when "option list"
            [profile.option_lists.get_option_list(sources)]
          when "vocabulary"
            [CCU::ValueSources::Vocabulary.new(sources)]
          when "authority"
            sources.split(",")
              .select { |source| profile.authorities.include?(source) }
              .map do |source|
                CCU::ValueSources::Authority.new(source, profile)
              end
          end
        end
      end
    end
  end
end
