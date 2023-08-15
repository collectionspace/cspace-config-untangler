# frozen_string_literal: true

module CspaceConfigUntangler
  # Namespace for validation methods
  module Validate
    module_function

    def opt_set(opts, name, val)
      if opts.any?(val)
        val
      else
        formatted = opts.map{ |sym| sym.inspect}
          .join(", ")
        fail(
          ArgumentError,
          "#{name} must be one of: #{formatted}")
      end
    end
    private_class_method :opt_set

    def date_mode(mode)
      opts = %i[collapsed expanded]
      opt_set(opts, "datemode", mode)
    end

    def out_mode(mode)
      opts = %i[expert friendly]
      opt_set(opts, "outmode", mode)
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
