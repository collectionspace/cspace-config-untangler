# frozen_string_literal: true

module CspaceConfigUntangler
  module Forms
    # Logs any unknown/unhandled keys, and any unexpected values of known
    # keys.
    #
    # So far, I have proceeded on the assumption that this code only has to
    # deal with data in the `props` key of any child. This will log any
    # populated other keys to indicate that there is a new data pattern to
    # account for
    class ChildKeyChecker
      EMPTY_KEYS = %w[key ref _owner].freeze
      POPULATED_KEYS = %w[props].freeze
      KNOWN_KEYS = (EMPTY_KEYS + POPULATED_KEYS).freeze

      def initialize
      end

      # @param child [Hash]
      # @param props [CCU::Forms::Props]
      def call(child, props)
        result = []
        check_for_unknown_keys(child, props, result)
        check_for_missing_keys(child, props, result)
        verify_empty_keys(child, props, result)
        verify_populated_keys(child, props, result)
        result.uniq
      end

      private

      def check_for_unknown_keys(child, props, result)
        chk = child.keys - KNOWN_KEYS
        return if chk.empty?

        chk.each do |key|
          CCU.log.warn("FORM STRUCTURE: NEW/UNHANDLED CHILD HASH KEY(S): "\
                       "#{formatted_key(props, key)}")
        end
        result << :ok
      end

      def check_for_missing_keys(child, props, result)
        chk = KNOWN_KEYS - child.keys
        return if chk.empty?

        chk.each do |key|
          CCU.log.warn("FORM STRUCTURE: MISSING HASH KEY: "\
                       "#{formatted_key(props, key)}")
        end
        result << :ok
      end

      def verify_empty_keys(child, props, result)
        not_empty = EMPTY_KEYS.select { |key| child[key] }
        return if not_empty.empty?

        not_empty.each do |key|
          CCU.log.warn("FORM STRUCTURE: EXPECTED EMPTY CHILD HASH KEY IS "\
                       "NON-NIL: "\
                       "#{formatted_key(props, key)} has value: "\
                       "#{hash[key]}")
        end
        result << :ok
      end

      def verify_populated_keys(child, props, result)
        empty = POPULATED_KEYS.select { |key| child[key].empty? }
        return if empty.empty?

        empty.each do |key|
          CCU.log.info("FORM STRUCTURE: EMPTY #{key.upcase}: "\
                       "#{props.profile.name} - "\
                       "#{props.rectype.name} - "\
                       "#{props.form.name} contains empty #{key} value under "\
                       "#{props.formatted_ui_path}")
        end
        result << :skip
      end

      def formatted_key(props, key) = "#{props.warning_id} #{key}"
    end
  end
end
