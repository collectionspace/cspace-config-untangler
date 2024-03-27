module CspaceConfigUntangler
  module RecordMapper
    class Validator
      attr_reader :path, :valid, :errors, :validated
      def initialize(path)
        @path = path
        @valid = false
        @validated = false
        @errors = []
        begin
          @mapper = JSON.parse(File.read(@path))
        rescue JSON::ParserError
          @errors << "#{@path} is not a valid JSON file"
          @mapper = nil
        end
      end

      def validate
        @validated = true
        return if @mapper.nil?
        results = [
          main_keys_present,
          has_profile_basename,
          has_recordtype,
          has_version,
          has_ns_uris,
          has_id_field,
          has_field_mapping_namespaces,
          term_source_types_ok
        ]
        @valid = true if results.uniq == [true]
      end

      def report
        validate unless @validated
        unless @valid
          puts ""
          puts "INVALID: #{@path}"
          @errors.uniq.each { |err| puts "  #{err}" }
          puts ""
        end
      end

      private

      def main_keys_present
        expected = %w[config docstructure mappings]
        keys = @mapper.keys
        diff = expected - keys
        if diff.empty?
          true
        else
          diff.each { |key| @errors << "Missing top-level key: #{key}" }
          false
        end
      end

      def has_profile_basename
        if @mapper["config"]["profile_basename"].blank?
          @errors << "Profile lacks config/profile_basename"
          false
        else
          true
        end
      end

      def has_recordtype
        if @mapper["config"]["recordtype"].blank?
          @errors << "Profile lacks config/recordtype"
          false
        else
          true
        end
      end

      def has_version
        if @mapper["config"]["version"].blank?
          @errors << "Profile lacks config/version"
          false
        else
          true
        end
      end

      def has_ns_uris
        ns_hash = @mapper.dig("config", "ns_uri")
        if ns_hash.nil?
          @errors << "No namespace hash in config"
          return false
        end

        null_uris = ns_hash.select { |ns, uri| uri.nil? }
        if null_uris.empty?
          true
        else
          null_uris.keys.each { |ns|
            @errors << "No namespace URI extracted for #{ns}"
          }
          false
        end
      end

      def has_id_field
        id_field = @mapper.dig("config", "identifier_field")
        if id_field.blank?
          @errors << "No identifier field specified in config"
          false
        else
          true
        end
      end

      def has_field_mapping_namespaces
        mappings = @mapper.dig("mappings")
        if mappings.blank?
          @errors << "No field mappings specified"
          return false
        end

        missing_ns = mappings.select { |mapping| mapping["namespace"].blank? }
        if missing_ns.empty?
          true
        else
          missing_ns.each { |mapping|
            @errors << "Field mapping(s) for #{mapping["fieldname"]} lack(s) namespace"
          }
          false
        end
      end

      def term_source_types_ok
        mappings = @mapper.dig("mappings")
        if mappings.blank?
          @errors << "No field mappings specified"
          return false
        end
        not_ok = mappings.select { |mapping|
          mapping["source_type"].start_with?("invalid source type")
        }
        if not_ok.empty?
          true
        else
          not_ok.each { |mapping|
            @errors << "Source type for #{mapping["fieldname"]} is not an option_list, vocabulary, or authority."
          }
          false
        end
      end
    end
  end
end
