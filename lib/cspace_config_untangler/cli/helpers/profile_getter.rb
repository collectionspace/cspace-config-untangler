# frozen_string_literal: true

module CspaceConfigUntangler
  module Cli
    module Helpers
      class ProfileGetter
        # @param opt_profiles [String]
        # @param mode [:uiconfig, :api]
        def self.call(opt_profiles, mode = :uiconfig)
          return [CCU.main_profile] unless opt_profiles
          return [CCU.main_profile] if opt_profiles.empty?
          return all_profiles(mode) if opt_profiles == "all"

          profiles = opt_profiles.split(",").map(&:strip)
          get(profiles, mode)
        end

        private_class_method

        def self.all_profiles(mode)
          all = [CCU.main_profile, CCU.profiles].compact.flatten.uniq
          return all if mode == :uiconfig

          for_api(all)
        end

        def self.get(profiles, mode)
          case mode
          when :uiconfig
            acc = []
            profiles.each do |profile|
              if all_profiles(mode).include?(profile)
                acc << profile
              else
                puts "Unknown profile \"#{profile}\" will be ignored..."
              end
            end
            acc.uniq
          when :api
            for_api(profiles)
          end
        end

        def self.for_api(profiles)
          profiles.map { |profile| profile.split("_").first }
        end
      end
    end
  end
end
