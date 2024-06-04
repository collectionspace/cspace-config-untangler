# frozen_string_literal: true

module CspaceConfigUntangler
  module Vocabs
    # Represents a vocabulary item (e.g. a term in a vocabulary)
    class VocabItem
      KEEP_KEYS = {
        "csid" => :@csid,
        "uri" => :@uri,
        "refName" => :@refname,
        "updatedAt" => :@updated,
        "workflowState" => :@workflow_state,
        "proposed" => :@proposed,
        "termStatus" => :@status,
        "shortIdentifier" => :@short_identifier,
        "displayName" => :@display_name
      }

      attr_reader :profile, :vocab, :csid, :uri, :refname, :updated,
        :workflow_state, :proposed, :status, :short_identifier, :display_name,
        :client

      # @param vocab [CCU::Vocabs::Vocab]
      # @param definition [Hash] parsed record from Client response
      def initialize(vocab, definition)
        @vocab = vocab
        @profile = vocab.profile
        @client = vocab.client
        definition.each do |key, val|
          next unless KEEP_KEYS.key?(key)

          instance_variable_set(KEEP_KEYS[key], val)
        end
      end

      def to_stdout(pad = 4)
        "#{" " * pad} #{display_name} #{short_identifier} #{csid} "\
          "Updated: #{updated} Uses: #{uses}"
      end

      def uses = @uses ||= get_uses

      private def get_uses
        resp = client.get("#{uri}/refObjs")
        case resp.status_code
        when 200
          resp.parsed.dig("authority_ref_doc_list", "totalItems")
        else
          "#{resp.status_code} error checking uses"
        end
      end

      def to_s
        "<##{self.class}:#{object_id.to_s(8)} #{id}>"
      end
      alias_method :inspect, :to_s

      def id = "#{vocab.id} #{display_name} #{short_identifier}"
    end
  end
end
