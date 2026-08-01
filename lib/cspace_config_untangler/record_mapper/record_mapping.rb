# frozen_string_literal: true

module CspaceConfigUntangler
  module RecordMapper
    class RecordMapping
      ::RecordMapping = CspaceConfigUntangler::RecordMapper::RecordMapping
      include JsonWritable

      attr_reader :profile, :rectype, :subtype, :style, :path

      # @param profile [CCU::Profile]
      # @param rectype [CCU::RecordType]
      # @param subtype [NilValue, Hash] like
      #   `{name: "Local", subtype: "person"}`
      # @param style %i[csvimporter datatoolkit]
      # @param path [String]
        @profile = profile
        @rectype = rectype
        @subtype = subtype
        @style = style
        @config = profile.config
        @path = path
      end

      def hash = @hash ||= build_hash

      def write = to_json(data: hash, output: path)

      def mappings
        @mappings ||= rectype.batch_mappings
      end

      def to_s
        "<##{self.class}:#{object_id.to_s(8)}\n"\
          "  profile: #{profile}\n"\
          "  rectype: #{rectype}\n"\
          "  subtype: #{subtype.inspect}\n"\
          "  style: #{style.inspect}\n"\
          "  path: #{path.inspect}>"
      end
      alias_method :inspect, :to_s

      private

      attr_reader :config

      def build_hash
        h = {}
        h[:config] = {}
        h[:config][:dataConfigType] = "record type" if style == "new"
        h[:config][:profile_basename] = profile.basename
        h[:config][:version] = profile.readable_version
        h[:config][:recordtype] = rectype.name
        add_display_name if style == "new"
        h[:config][:document_name] =
          config.dig("recordTypes", rectype.name, "serviceConfig",
            "documentName")
        h[:config][:service_name] =
          config.dig("recordTypes", rectype.name, "serviceConfig",
            "serviceName")
        h[:config][:service_path] =
          config.dig("recordTypes", rectype.name, "serviceConfig",
            "servicePath")
        h[:config][:service_type] = rectype.service_type
        h[:config][:object_name] =
          config.dig("recordTypes", rectype.name, "serviceConfig",
            "objectName")
        h[:config][:ns_uri] = NamespaceUris.new(profile_config: config,
          rectype: rectype.name,
          mapper_config: h[:config]).hash
        h[:config][:identifier_field] = rectype.id_field
        h[:config][:search_field] = rectype.search_field
        if rectype.service_type == "authority"
          h[:config][:authority_subtypes] =
            rectype.subtypes
        end
        h[:docstructure] = {}
        create_hierarchy(h)
        h[:mappings] = mappings.map { |m| m.to_h }

        append_subtype(h) if subtype
        h
      end

      def add_display_name(h)
        msg = get_display_name
        return unless msg

        h[:config][:display_name] = msg
        h
      end

      def get_display_name
        msg = rectype.display_name
        return unless msg
        return msg unless subtype

        "#{msg}/#{subtype[:name]}"
      end

      def create_hierarchy(h)
        # top level keys are the namespaces
        mappings.each do |m|
          h[:docstructure][m.namespace] = {}
        end

        mappings.each do |m|
          next if m.data_type.nil? && m.xpath.nil?

          levels = m.xpath.clone
          done = []
          while levels.size > 0
            thislevel = levels.shift
            path = done.clone << thislevel
            add_key = if h[:docstructure][m.namespace].dig(*path)
              false
            else
              true
            end
            if add_key
              add_path = if done.empty?
                h[:docstructure][m.namespace]
              else
                h[:docstructure][m.namespace].dig(*done)
              end
              add_path[thislevel] = {}
            end
            done << thislevel
          end
        end
        h
      end

      def append_subtype(h)
        h[:config][:authority_type] = h[:config][:service_path]
        h[:config][:authority_subtype] = subtype[:subtype]
        h
      end
    end
  end
end
