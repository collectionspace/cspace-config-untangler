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

      mode_option = [:mode, {
        desc: "Output mode in which to run command",
        type: :string,
        enum: %w[csv stdout],
        default: "stdout",
        aliases: "-m"
      }]

      outpath_option_hash = {
        desc: "Path to output file, if run in csv mode",
        type: :string,
        aliases: "-o"
      }

      desc "duplicate", "List vocabularies defined more than once in a profile"
      method_option(*mode_option)
      method_option :outpath, **outpath_option_hash.merge({
        default: File.join(Bundler.root, "data", "duplicate_vocabs.csv")
      })
      def duplicate
        set_env(options[:env])

        CCU::Vocabs::DuplicateVocabReport.run(
          profiles: get_profiles(:api),
          mode: options[:mode].to_sym,
          outpath: options[:outpath]
        )
      end

      desc "duplicate_terms", "List vocabulary terms defined more than once "\
        "in a vocabulary"
      method_option(*mode_option)
      method_option :outpath, **outpath_option_hash.merge({
        default: File.join(Bundler.root, "data", "duplicate_vocab_terms.csv")
      })
      option :vocabs,
        desc: "Short identifiers of vocabs to check",
        type: :array,
        default: ["all"],
        aliases: "-v"
      def duplicate_terms
        set_env(options[:env])

        get_profiles(:api).each do |profile|
          duplicates = filter_vocabs(
            CCU::Vocabs::Getter.call(profile), options[:vocabs]
          ).reject { |vocab| vocab.duplicate_terms.blank? }
          next if duplicates.empty?

          puts profile
          duplicates.each do |vocab|
            puts vocab.to_stdout
            vocab.duplicate_terms.each do |name, items|
              puts "    #{name}"
              items.each { |item| puts item.to_stdout(6) }
            end
          end
        end
      end

      desc "short_ids", "List short identifiers of defined vocabularies"
      def short_ids
        set_env(options[:env])

        get_profiles(:api).each do |profile|
          puts profile
          puts CCU::Vocabs::Getter.call(profile)
            .map { |vocab| "  #{vocab.short_identifier}" }
            .sort
        end
      end

      no_commands do
        def set_env(env)
          return if env == "demo"

          CCU.config.instance_env = env.to_sym
        end

        def filter_vocabs(all, keep)
          return all if keep == ["all"]

          all.select { |vocab| keep.include?(vocab.short_identifier) }
        end
      end
    end
  end
end
