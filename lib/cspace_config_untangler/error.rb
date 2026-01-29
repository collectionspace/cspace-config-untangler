# frozen_string_literal: true

module CspaceConfigUntangler
  # Mixin module included in any application-specific error classes
  #
  # This allows each application-specific error to:
  #
  # - be subclassed to proper exception class in standard Ruby exception
  #   hierarchy
  # - be identified or rescued by standard Ruby exception
  #   hierarchy ancestor, OR by application-specific error status
  module Error
    # Any application-specific error methods can be added here.
  end

  class ExtractMessagesUndefinedError < StandardError
    include Error

    def initialize
      msg = "You must define an :extract_messages method in any class "\
        "that includes Messageable"
      super(msg)
    end
  end
end
