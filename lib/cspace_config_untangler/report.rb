# frozen_string_literal: true

require 'fileutils'

module CspaceConfigUntangler
  # Namespace for report generators
  module Report
    module_function

    def qa_reports(release:)
      CCU.config.release = release
      prev = CCU.prev_release

      dir = CCU.data_reference_dir
      FileUtils.mkdir_p(dir) unless Dir.exist?(dir)
      FileUtils.rm(Dir.new(dir).children.map{ |fn| File.join(dir, fn) })

      CCU::Report::QaAllFields.call(release: release)
      CCU::Report::QaChangedFields.call(release: release)
      CCU::Report::QaDeletedFields.call(release: release)
      CCU::Report::NonuniqueFieldPaths.call(profiles: "all", mode: :release)
      CCU::Report::NonuniqueFieldNames.call(profiles: "all", mode: :release)
      CCU::Report::XpathDepthCheck.call
    end

    def reference_reports(release)
      CCU.config.release = CCU::Validate.release(release)
      dir = CCU.data_reference_dir(release)
      FileUtils.mkdir_p(dir) unless Dir.exist?(dir)

      CCU::Report::AllFieldsGenerator.call(release: release)
      CCU::Report::AllFieldsGenerator.call(
        release: release,
        datemode: :collapsed
      )
      CCU::Report::MultiAuthRepeatableFieldsGenerator.call(
        release: release
      )
      CCU::Report::StructuredDateFieldsGenerator.call(
        release: release
      )
      CCU::Cli::Helpers::ProfileGetter.call('all').each do |profile|
        CCU::Report::ProfileFieldsGenerator.call(
          release: release,
          profile: profile
        )
      end
    end

    def deversion_for_qa(row)
      fid = row["fid"]
      row['fid'] = fid.sub(/_\d+(-\d+){2} /, ' ')
      row['profile'] = row['profile'].sub(/_\d+(-\d+){2}/, '')
      row
    end

    def get_qa_table(release: CCU.release, prev: false)
      if prev
        current_release = release.dup
        CCU.config.release = CCU.prev_release
      end

      path = CCU.allfields_path
      unless File.exist?(path)
        CCU::Report::AllFieldsGenerator.call(
          release: CCU.release,
          datemode: :collapsed
        )
      end

      CCU.config.release = current_release if prev

      CSV.parse(File.read(path), headers: true)
        .map{ |row| deversion_for_qa(row) }
    end

    def simplify_allfields(row)
      %w[fid namespace namespace_for_id field_id].each do |field|
        row.delete(field)
      end
      row
    end
  end
end
