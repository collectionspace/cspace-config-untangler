# frozen_string_literal: true

module CspaceConfigUntangler
  class UpgradeWarner
    def initialize
      @warned = []
    end

    # @param target_version [String] of release for which warnings should be
    #   emitted
    # @param issue [nil, String] Jira or other issue to check for information on
    #   the status of changes expected to impact this code
    def call(target_version:, issue: nil)
      return unless CCU.release.version == target_version
      source = caller(1..1).first
      warned_key = "#{target_version} #{source}"
      return if warned.include?(warned_key)

      basemsg = "Verify that code at the following location is still "\
        "needed with #{target_version}"
      msgissue = issue ? "(see #{issue})" : nil
      fullmsg = [basemsg, msgissue].compact.join(" ")
      warn([fullmsg, source].compact.join(":\n"))
      CCU.log.warn([fullmsg, source].compact.join(": "))
      warned << warned_key
    end

    private

    attr_reader :warned
  end
end
