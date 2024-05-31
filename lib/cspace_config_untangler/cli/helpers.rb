# frozen_string_literal: true

require_relative "helpers/profile_getter"

module CspaceConfigUntangler
  module Cli
    # Helper methods for CLI support
    module Helpers
      # @param mode [:uiconfig, :api]
      def get_profiles(mode = :uiconfig)
        CCU::Cli::Helpers::ProfileGetter.call(options[:profiles], mode)
      end

      def parse_rectypes
        rt = options[:rectypes]
        return [] if rt == "all" || rt == ["all"]
        return rt if rt.is_a?(Array)

        rt.split(",")
      end
    end
  end
end
