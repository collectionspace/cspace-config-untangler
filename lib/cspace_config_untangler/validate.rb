# frozen_string_literal: true

module CspaceConfigUntangler
  # Namespace for validation methods
  module Validate
    module_function

    def date_mode(mode)
      if %i[collapsed expanded].any?(mode)
        mode
      else
        fail(ArgumentError, 'mode must be :collaped or :expanded')
      end
    end

    def profile(val)
      known = CCU::Cli::Helpers::ProfileGetter.call('all')
      if known.any?(val)
        val
      else
        fail(ArgumentError, "profile must be one of: #{known.join('; ')}")
      end
    end

    def release(val)
      unless /^\d+(_\d+){1,2}$/.match?(val)
        fail(ArgumentError, 'release must follow pattern: #_# or #_#_#')
      end

      unless Dir.exist?(CCU.release_configs_dir(val))
        fail(ArgumentError, 'no configs directory for release')
      end

      val
    end
  end
end
