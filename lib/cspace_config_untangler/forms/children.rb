require_relative "properties"

module CspaceConfigUntangler
  module Forms
    class Children
      def initialize(formobj, parentprops, data)
        @form = formobj
        @parent = parentprops
        @children = standardize_form_data(data)
        unless @children.nil?
          @children.each { |child|
            CCU::Forms::Properties.new(@form, child["props"],
              @parent)
          }
        end
      end

      # Only one child in the UI config is represented as a hash, while multiple
      # children are represented as an array of hashes
      # This method converts a single child into an array containing one hash
      def standardize_form_data(data)
        if data.is_a?(Hash)
          result = [data]
        elsif data.is_a?(Array)
          result = data
        end
        report_non_nil_and_missing_keys(result)
        result
      end

      # form children have keys: key, ref, props, and _owner
      # I'm proceeding based on the assumption that I only care about props because
      #  the others are always nil
      # This logs any non-nil values for key, ref, or _owner so I can inspect
      def report_non_nil_and_missing_keys(data)
        unless data.nil?
          data.each { |h|
            %w[key ref _owner].each { |k| check_key(h, k) }
          }
        end
      end

      def check_key(hash, key)
        if hash.has_key?(key)
          CCU.log.warn("FORM STRUCTURE: NON-NIL HASH KEY: #{profile} - #{rectype} - #{@form.name} #{@parent.ui_path.join(" / ")} #{key} has value: #{hash[key]}") unless hash[key].nil?
        else
          CCU.log.warn("FORM STRUCTURE: MISSING HASH KEY: #{profile} - #{rectype} - #{@form.name} #{@parent.ui_path.join(" / ")} missing #{key} key")
        end
      end
    end
  end
end
