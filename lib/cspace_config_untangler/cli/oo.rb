# frozen_string_literal: true

require "digest"

require_relative "subcommand_base"

module CspaceConfigUntangler
  module Cli
    class Oo < SubcommandBase
      desc "write",
        "Writes JSON optlist override data configs for the configs currently "\
        "in `CCU.oo_config_dir`"
      shared_option :output_dir, default: CCU.oo_data_config_path
      def write
        Dir.new(CCU.oo_config_dir).children
          .reject { |child| child == ".keep" }
          .each do |tenant|
          CCU::OptlistOverride::Writer.call(
            File.join(CCU.oo_config_dir, tenant)
          )
        end
      end
    end
  end
end
