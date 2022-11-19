# frozen_string_literal: true

require 'fileutils'

module CspaceConfigUntangler
  # Namespace for report generators
  module Report
    module_function

    def reference_reports(release)
      dir = CCU.data_reference_dir(release: release)
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
      row['fid'] = row['fid'].sub(/_\d+(-\d+){2} /, ' ')
      row['profile'] = row['profile'].sub(/_\d+(-\d+){2}/, '')
      row
    end

    def get_qa_table(release)
      vrelease = CCU::Validate.release(release)
      path = CCU.allfields_path(release: vrelease)

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
