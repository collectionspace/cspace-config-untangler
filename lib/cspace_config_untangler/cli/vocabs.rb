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
      outpath_option_hash = {
        desc: "Path to output file, if run in csv mode"
      }

      desc "all", "List vocabularies defined in profile(s)"
      shared_options :profiles, :env, :output_mode
      out_default = outpath_option_hash.merge({
        default: File.join(CCU.datadir, "vocabs.csv")
      })
      shared_option :output_path, **out_default
      def all
        set_env(options[:env])

        CCU::Vocabs::AllVocabReport.run(
          profiles: get_profiles(:api),
          mode: options[:output_mode].to_sym,
          outpath: options[:output_path]
        )
      end

      desc "duplicate", "List vocabularies defined more than once in a profile"
      shared_options :profiles, :env, :output_mode
      shared_option :output_path, **outpath_option_hash.merge({
        default: File.join(CCU.datadir, "duplicate_vocabs.csv")
      })
      def duplicate
        set_env(options[:env])

        CCU::Vocabs::DuplicateVocabReport.run(
          profiles: get_profiles(:api),
          mode: options[:output_mode].to_sym,
          outpath: options[:output_path]
        )
      end

      desc "duplicate_terms", "List vocabulary terms defined more than once "\
        "in a vocabulary"
      long_desc "List vocabulary terms defined more than once in a "\
        "vocabulary.\n\nA term is considered to be defined more than once "\
        "if more than one term in the vocabulary shared the same downcased "\
        "display name."
      shared_options :profiles, :env, :output_mode
      shared_option :output_path, **outpath_option_hash.merge({
        default: File.join(CCU.datadir, "duplicate_vocab_terms.csv")
      })
      option :vocabs,
        desc: "Short identifiers of vocabs to check",
        type: :array,
        default: ["all"],
        aliases: "-v"
      option :usage,
        desc: "Whether to report usage of duplicate terms reported. This can "\
        "cause the report to take a much longer time to run.",
        type: :boolean,
        default: false,
        aliases: "-u"
      def duplicate_terms
        set_env(options[:env])

        CCU::Vocabs::DuplicateTermReport.run(
          profiles: get_profiles(:api),
          vocabs: options[:vocabs],
          usage: options[:usage],
          mode: options[:output_mode].to_sym,
          outpath: options[:output_path]
        )
      end

      desc "short_ids", "List short identifiers of defined vocabularies"
      shared_options :profiles
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
