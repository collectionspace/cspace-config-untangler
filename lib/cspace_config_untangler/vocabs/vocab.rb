# frozen_string_literal: true

module CspaceConfigUntangler
  module Vocabs
    # Represents a vocabulary
    class Vocab
      KEEP_KEYS = {
        "csid" => :@csid,
        "uri" => :@uri,
        "refName" => :@refname,
        "updatedAt" => :@updated,
        "workflowState" => :@workflow_state,
        "shortIdentifier" => :@short_identifier,
        "displayName" => :@display_name
      }

      attr_reader :profile, :csid, :uri, :refname, :updated, :workflow_state,
        :short_identifier, :display_name,
        :client
      private attr_reader :configprofilename

      # @param definition [Hash] parsed record from Client response
      # @param profilename [String]
      # @param client [CollectionSpace::Client]
      # @param configprofilename [nil, String]
      def initialize(definition, profilename, client, configprofilename)
        @profile = profilename
        @client = client
        @configprofilename = configprofilename
        definition.each do |key, val|
          next unless KEEP_KEYS.key?(key)

          instance_variable_set(KEEP_KEYS[key], val)
        end
      end

      def to_stdout(pad = 2)
        "#{" " * pad}#{short_identifier} -- #{csid} -- Updated: #{updated}\n"\
          "    Used by: #{formatted_used_by}"
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
        return :no_config_profile unless config_profile

        fields = config_profile.fields
          .select do |field|
          field.vocabulary_controlled? &&
            field.controlled_by?(short_identifier)
        end
        return :not_used if fields.empty?

        fields
      end

      def config_profile = @config_profile ||= get_config_profile

      private def get_config_profile
        return unless configprofilename

        CCU::Profile.new(profile: configprofilename, rectypes: [])
      end

      def to_s
        "<##{self.class}:#{object_id.to_s(8)} #{id}>"
      end
      alias_method :inspect, :to_s

      def id = "#{profile} #{short_identifier}"
    end
  end
end
