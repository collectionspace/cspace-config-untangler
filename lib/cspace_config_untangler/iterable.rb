# frozen_string_literal: true

module CspaceConfigUntangler
  module Iterable
    def extract_by_key(hash, key_value, extracted = [])
      hash.each do |k, v|
        # If v is nil, an array is being iterated and the value is k.
        # If v is not nil, a hash is being iterated and the value is v.
        value = v || k

        if value.is_a?(Hash) || value.is_a?(Array)
          extracted << v if v && k == key_value
          extract_by_key(value, key_value, extracted)
        end
      end
      extracted
    end
  end
end
