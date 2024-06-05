# frozen_string_literal: true

module CspaceConfigUntangler
  module Vocabs
    # Represents a vocabulary item (e.g. a term in a vocabulary)
    class VocabItem
      KEEP_KEYS = {
        "displayName" => :@display_name,
        "shortIdentifier" => :@short_identifier,
        "workflowState" => :@workflow_state,
        "updatedAt" => :@updated,
        "termStatus" => :@status,
        "proposed" => :@proposed,
        "csid" => :@csid,
        "uri" => :@uri,
        "refName" => :@refname
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

      def headers(usage: false) = @headers ||= get_headers(usage)

      private def get_headers(usage)
        base = %w[profile vocab] +
          KEEP_KEYS.values.map { |val| val.to_s.tr("@", "") }
        return base unless usage

        base + %w[uses]
      end

      def to_csv(usage: false)
        headers(usage: usage).map { |hdr| get_csv_val(hdr) }
      end

      private def get_csv_val(hdr)
        case hdr
        when "vocab"
          vocab.short_identifier
        else
          send(hdr.to_sym)
        end
      end

      def to_stdout(pad: 4, usage: false)
        base = "#{" " * pad} #{display_name} #{short_identifier} #{csid} "\
          "Updated: #{updated}"
        return base unless usage

        "#{base} Uses: #{uses}"
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
