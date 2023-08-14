require_relative 'helpers'

module CspaceConfigUntangler
  module Cli
    class AuthoritiesCli < Thor
      include CCU::Cli::Helpers

      desc 'all_defined', 'List all authority vocabularies defined in '\
        'selected profiles'
      def all_defined
          puts all_authvocabs
      end

      desc 'defined', 'List authority vocabularies defined in profiles'
      def defined
        get_profiles.each do |profile|
          puts profile
          CCU::Profile.new(profile: profile).authorities
            .each{ |auth| puts "  #{auth}" }
        end
      end

      desc 'profiles_defining AUTHVOCAB', 'Profiles with the given authority '\
        'vocabulary defined'
      def profiles_defining(authvocab)
         profiles_def(authvocab).each{ |profile| puts profile.name }
      end

      desc 'unused', 'List authority vocabularies defined in profiles, '\
        'but not used to control any fields'
      def unused
        get_profiles.each do |profile|
          puts profile
          unused = CCU::Profile.new(profile: profile).unused_authority_vocabs
          if unused.empty?
            puts "  n/a"
          else
            unused.each{ |auth| puts "  #{auth}" }
          end
        end
      end

      desc 'with_profiles', 'Lists all defined authority vocabs, with the '\
        'profiles defining said vocab under each'
      def with_profiles
        all_authvocabs.each do |auth|
          puts auth
          puts profiles_def(auth).map{ |profile| "  #{profile.name}" }
        end
      end

      no_commands do
        def all_authvocabs
          get_profiles.map{ |profile| CCU::Profile.new(profile: profile).authorities }
            .flatten
            .uniq
            .sort
        end

        def profiles_def(authvocab)
          get_profiles.map{ |profile| CCU::Profile.new(profile: profile) }
            .select{ |profile| profile.authorities.include?(authvocab) }
        end
      end
    end
  end
end
