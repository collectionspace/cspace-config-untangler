# frozen_string_literal: true

module CspaceConfigUntangler
  module Report
    # Mixin module for reports, etc.
    #
    # ## Implementation
    #
    # Class mixing in must respond to `:release`
    module BotgardenDroppable
      def drop_botgarden? = CCU.release.gt("8_3")

      # @param rows [Array]
      def drop_botgarden(rows)
        rows.reject { |row| row["profile"] == "botgarden" }
      end
    end
  end
end
