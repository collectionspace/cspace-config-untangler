# frozen_string_literal: true

module CspaceConfigUntangler
  module Fields
    module ValueSources
      class SourceExtractor
        def self.call(type, field_hash, profile)
          sources = field_hash.dig("view", "props", "source")

          case type
          when "no source"
            [CCU::ValueSources::NoSource.new]
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
          else
            warn("Unknown value source pattern, #{__FILE__}, #{__LINE__}")
            puts field_hash
          end
        end
      end
    end
  end
end
