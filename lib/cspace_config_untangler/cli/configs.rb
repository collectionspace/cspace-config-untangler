# frozen_string_literal: true

require "fileutils"

require_relative "subcommand_base"

module CspaceConfigUntangler
  module Cli
    class Configs < SubcommandBase
      desc "fetch_community_supported",
        "Download UI configs for community supported profiles"
      shared_options :release, :env
      def fetch_community_supported
        CCU::UiConfig.fetch_community_profiles(
          release: options[:release], env: options[:env]
        )
      end

      desc "fetch_hosted",
        "Download UI configs for Lyrasis-hosted instances"
      option :tenants,
        desc: "Optional list of instance tenant names to download",
        type: :array,
        required: false,
        default: nil,
        aliases: "-t"
      def fetch_hosted
        CCU::UiConfig.fetch_hosted(options[:tenants])
      end

      desc "readable",
        "REFORMATS (in place) JSON profile configs so that they are not one "\
        "very long line. Non-destructive if run over JSON multiple times."
      shared_options :profiles
      def readable
        message = []
        get_profiles.each do |p|
          message << "Reformatting #{p} config"
          oldprofile = JSON.parse(File.read("#{CCU.configdir}/#{p}.json"))
          File.open("#{CCU.configdir}/#{p}.json", "w") do |f|
            f.puts JSON.pretty_generate(oldprofile)
          end
        end
        say(message.join("\n"))
      end

      desc "switch_release", "Deletes configs and copies community profile "\
        "configs from specified release as current configs"
      shared_options :release
      def switch_release
        CCU.config.release = options[:release]
        puts CCU::Cli::Helpers::ProfileGetter.call("all")
      end
    end
  end
end
