require_relative "helpers"

module CspaceConfigUntangler
  module Cli
    class AuthoritiesCli < Thor
      include CCU::Cli::Helpers

      desc "defined", "List authority vocabularies defined in profiles"
      def defined
        get_profiles.each do |profile|
          puts profile
          CCU::Profile.new(profile: profile).authorities
            .each { |auth| puts "  #{auth}" }
        end
      end

      desc "profiles_defining AUTHVOCAB", "Profiles with the given authority "\
        "vocabulary defined"
      def profiles_defining(authvocab)
        profiles_def(authvocab).each { |profile| puts profile.name }
      end

      desc "report", "Write sortable/filterable CSV of authority info"
      option :output,
        desc: "Path to output file",
        default: nil,
        aliases: "-o"
      def report
        baseparam = {profiles: options[:profiles]}
        params = if options[:output]
          baseparam.merge(
            {target: File.expand_path(options[:output])}
          )
        else
          baseparam
        end

        CCU::Report::AuthorityVocabUse.call(**params)
      end

      desc "unused", "List authority vocabularies defined in profiles, "\
        "but not used to control any fields"
      def unused
        get_profiles.each do |profile|
          puts profile
          unused = CCU::Profile.new(profile: profile).unused_authority_vocabs
          if unused.empty?
            puts "  n/a"
          else
            unused.each { |auth| puts "  #{auth}" }
          end
        end
      end

      no_commands do
        def profiles_def(authvocab)
          options[:profiles] = "all"
          get_profiles.map { |profile| CCU::Profile.new(profile: profile) }
            .select { |profile| profile.authorities.include?(authvocab) }
        end
      end
    end
  end
end
