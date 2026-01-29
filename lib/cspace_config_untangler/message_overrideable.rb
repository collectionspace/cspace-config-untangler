# frozen_string_literal: true

module CspaceConfigUntangler
  # Mixin module with shared logic for converting profile-level messages into
  #  message config hashes
  module MessageOverrideable
    def convert_to_config(id, msg)
      {"id" => id, "defaultMessage" => msg}
    end
  end
end
