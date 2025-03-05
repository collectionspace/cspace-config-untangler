# frozen_string_literal: true

module CspaceConfigUntangler
  module Fields
    module ValueSources
      class SourceExtractor
        def self.call(type, field_hash, profile)
          return [CCU::ValueSources::NoSource.new] if type == "no source"

          sources = field_hash.dig("view", "props", "source")
          unless sources
            CCU.log.warn("No value source specified for "\
                         "#{type}-controlled field, "\
                         "#{field_hash} -- #{__FILE__}, #{__LINE__}")
            return [CCU::ValueSources::NoSource.new]
          end

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
          else
            warn("Unknown value source pattern, #{__FILE__}, #{__LINE__}")
            puts field_hash
          end
        end
      end
    end
  end
end
