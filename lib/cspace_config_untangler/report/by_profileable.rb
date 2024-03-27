# frozen_string_literal: true

require "csv"
require "fileutils"

module CspaceConfigUntangler
  module Report
    # Mixin module to write profile-specific reports to subdirectories
    #
    # IMPLEMENTATION NOTES
    #
    # Including class must respond to :basedir and :basefilename
    module ByProfileable
      private

      def to_csv(profile, rows)
        headers = rows.first.to_h.keys

        path = path_for(profile)
        CSV.open(path, "w") do |csv|
          csv << headers
          rows.each { |row| csv << row.values_at(*headers) }
        end

        puts "Wrote #{path}"
      end

      def dir_for(profile)
        dir = File.join(basedir, profile)
        FileUtils.mkdir_p(dir) unless Dir.exist?(dir)
        dir
      end

      def path_for(profile)
        File.join(dir_for(profile), "#{profile}#{basefilename}")
      end
    end
  end
end
