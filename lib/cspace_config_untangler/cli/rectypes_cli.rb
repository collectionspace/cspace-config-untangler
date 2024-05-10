# frozen_string_literal: true

require_relative "helpers"

module CspaceConfigUntangler
  module Cli
    class RecTypesCli < Thor
      include CCU::Cli::Helpers
      desc "list", "Lists record types in each profile"
      def list
        get_profiles.each do |p|
          puts "\n#{p}:"
          puts CCU::Profile.new(profile: p).rectypes.map { |e| "  #{e.name}" }
        end
      end
    end
  end
end
