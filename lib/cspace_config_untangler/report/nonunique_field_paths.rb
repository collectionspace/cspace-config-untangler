# frozen_string_literal: true

module CspaceConfigUntangler
  module Report
    class NonuniqueFieldPaths

      class << self
        def call(...)
          self.new(...).call
        end
      end

      # @param profiles [nil, String]
      # @param mode [:stdout, :release]
      def initialize(profiles: nil, mode: :stdout)
        @profiles = CCU::Cli::Helpers::ProfileGetter.call(profiles)
          .map{ |profile| CCU::Profile.new(profile: profile) }
        @mode = mode
      end

      def call
        result = profiles.map{ |profile| [profile, profile.nonunique_fields] }
          .to_h
          .reject{ |profile, info| info.empty? }
        result.empty? ? output_empty : output(result)
      end

      private

      attr_reader :profiles, :mode

      def output_empty
        puts "No non-unique field paths"
      end

      def output(result)
        warn("Implement output of non-unique field paths")
      end
    end
  end
end
