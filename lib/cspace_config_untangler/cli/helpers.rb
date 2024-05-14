# frozen_string_literal: true

require_relative "helpers/profile_getter"

module CspaceConfigUntangler
  module Cli
    # Helper methods for CLI support
    module Helpers
      def get_profiles
        CCU::Cli::Helpers::ProfileGetter.call(options[:profiles])
      end

      def parse_rectypes
        return [] if options[:rectypes] == "all"

        options[:rectypes].split(",")
      end
    end
  end
end
