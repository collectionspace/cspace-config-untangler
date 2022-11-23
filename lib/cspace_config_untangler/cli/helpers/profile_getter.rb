module CspaceConfigUntangler
  module Cli
    module Helpers
      class ProfileGetter
        def self.call(opt_profiles)
          return [CCU.main_profile] unless opt_profiles
          return [CCU.main_profile] if opt_profiles.empty?

          return self.all_profiles if opt_profiles == 'all'

          profiles = opt_profiles.split(',').map(&:strip)
          self.get(profiles)
        end

        private

        def self.all_profiles
          [CCU.main_profile, CCU.profiles].compact.flatten.uniq
        end

        def self.get(profiles)
          acc = []
          profiles.each{ |profile|
            if all_profiles.include?(profile)
              acc << profile
            else
              puts "Unknown profile \"#{profile}\" will be ignored..."
            end
          }
          return acc.uniq
        end
      end
    end
  end
end
