# frozen_string_literal: true

module CspaceConfigUntangler
  module Cli
    # Helper methods for CLI support
    module Helpers
      def get_profiles
        CCU::Cli::Helpers::ProfileGetter.call(options[:profiles])
      end
    end
  end
end
