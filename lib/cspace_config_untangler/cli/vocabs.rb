# frozen_string_literal: true

require_relative "subcommand_base"

module CspaceConfigUntangler
  module Cli
    # Commands to report on vocabularies (e.g. dynamic term lists) defined in a
    # CollectionSpace instance.
    #
    # @note These commands require a connection to the instance's
    #   services API. See the README's "Optional: create a client
    #   connection config file" section for more info on configuring
    #   such connections
    class Vocabs < CCU::Cli::SubcommandBase
      # include CCU::Cli::Helpers

      remove_class_option :rectypes

      class_option :env,
        desc: "Environment (demo, dev, qa) in which to run command. "\
        "Only has an effect on community-supported profiles.",
        type: :string,
        default: "demo",
        aliases: "-e",
        enum: %w[demo dev qa]

      desc "duplicate", "List vocabularies defined more than once in a profile"
      def duplicate
        set_env(options[:env])

        get_profiles(:api).each do |profile|
          CCU::Vocabs.duplicates(CCU::Vocabs::Getter.call(profile))
            .each do |name, vocabs|
              puts "#{profile} -- #{vocabs.first.display_name}"
              vocabs.sort_by { |vocab| vocab.updated }
                .each { |vocab| puts vocab.to_stdout }
            end
        end
      end

      no_commands do
        def set_env(env)
          return if env == "demo"

          CCU.config.instance_env = env.to_sym
        end
      end
    end
  end
end
