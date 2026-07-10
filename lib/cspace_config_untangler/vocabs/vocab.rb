# frozen_string_literal: true

require_relative "item_getter"

module CspaceConfigUntangler
  module Vocabs
    # Represents a vocabulary
    class Vocab
      KEEP_KEYS = {
        "displayName" => :@display_name,
        "shortIdentifier" => :@short_identifier,
        "workflowState" => :@workflow_state,
        "updatedAt" => :@updated,
        "csid" => :@csid,
        "uri" => :@uri,
        "refName" => :@refname
      }

      CSV_HEADERS = %w[profile ui_config] +
        KEEP_KEYS.values.map { |val| val.to_s.tr("@", "") } +
        ["used_by"]

      attr_reader :profile, :csid, :uri, :refname, :updated, :workflow_state,
        :short_identifier, :display_name,
        :client
      private attr_reader :configprofile

      # @param definition [Hash] parsed record from Client response
      # @param profilename [String]
      # @param client [CollectionSpace::Client]
      # @param configprofile [nil, CCU::Profile]
      def initialize(definition, profilename, client, configprofile)
        @profile = profilename
        @client = client
        @configprofile = configprofile
        definition.each do |key, val|
          next unless KEEP_KEYS.key?(key)

          instance_variable_set(KEEP_KEYS[key], val)
        end
      end

      # @return [Array<CCU::Vocabs::VocabItem>]
      def terms = @terms ||= get_terms

      private def get_terms
        puts "Harvesting terms for #{id}..."
        CCU::Vocabs::ItemGetter.call(self)
          .to_a
      end

      # @return [Hash{String=>Array<CCU::Vocabs::VocabItem>}]
      def duplicate_terms = @duplicate_terms ||= get_duplicate_terms

      private def get_duplicate_terms
        return [] if terms.empty?

        terms.group_by { |term| term.display_name.downcase }
          .reject { |term, arr| arr.length == 1 }
      end

      def to_csv
        CSV_HEADERS.map { |hdr| get_csv_val(hdr) }
      end

      private def get_csv_val(hdr)
        case hdr
        when "used_by"
          formatted_used_by
        when "ui_config"
          configprofile.name
        else
          send(hdr.to_sym)
        end
      end

      def to_stdout(pad = 2)
        indent = " " * (pad + 2)
        "#{" " * pad}#{short_identifier} -- #{csid} -- Updated: #{updated}\n"\
          "#{indent}Used by: #{formatted_used_by}"
      end

      def used_by = @used_by ||= get_used_by

      def formatted_used_by
        case used_by
        when :no_config_profile
          "[cannot check usage - no UI config for profile]"
        when :not_used
          "not used"
        else
          used_by.map { |field| field.friendly_label }
            .join("; ")
        end
      end

      private def get_used_by
        return :no_config_profile unless configprofile

        fields = configprofile.fields
          .select do |field|
          field.vocabulary_controlled? &&
            field.controlled_by?(short_identifier)
        end
        return :not_used if fields.empty?

        fields
      end

      def to_s
        "<##{self.class}:#{object_id.to_s(8)} #{id}>"
      end
      alias_method :inspect, :to_s

      def id = "#{profile} #{short_identifier}"
    end
  end
end
