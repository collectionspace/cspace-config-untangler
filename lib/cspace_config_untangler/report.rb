# frozen_string_literal: true

require "fileutils"

module CspaceConfigUntangler
  # Namespace for report generators
  module Report
    module_function

    extend Dry::Configurable

    setting :auth_vocab_report_path,
      default: nil,
      reader: true,
      constructor: ->(_v) do
        File.join(CCU.data_reference_dir, "authority_vocabulary_usage.csv")
      end
    setting :multi_auth_report_path,
      default: nil,
      reader: true,
      constructor: ->(_v) do
        File.join(CCU.data_reference_dir, "multi_auth_repeatable_fields.csv")
      end
    setting :structured_date_report_path,
      default: nil,
      reader: true,
      constructor: ->(_v) do
        File.join(CCU.data_reference_dir, "structured_date_fields.csv")
      end

    def qa_reports(release:, clean: false)
      CCU.config.release = release
      CCU.prev_release

      dir = CCU.data_reference_dir
      FileUtils.mkdir_p(dir) unless Dir.exist?(dir)
      if clean
        FileUtils.rm(Dir.new(dir).children.map { |fn| File.join(dir, fn) })
      end

      CCU::Report::QaAllFields.call(release: release)
      CCU::Report::QaChangedFields.call(release: release)
      CCU::Report::QaDeletedFields.call(release: release)
      CCU::Report::NonuniqueFieldPaths.call(profiles: "all", mode: :release)
      CCU::Report::NonuniqueFieldNames.call(profiles: "all", mode: :release)
      CCU::Report::XpathDepthCheck.call
      CCU::Report::UnusedAuthorityVocabs.call
    end

    def reference_reports(release, clean: false)
      CCU.config.release = CCU::Validate.release(release)
      dir = CCU.data_reference_dir(release)
      FileUtils.mkdir_p(dir) unless Dir.exist?(dir)
      if clean
        FileUtils.rm_f(Dir.new(dir).children.map { |fn| File.join(dir, fn) })
      end

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
      CCU::Report::AuthorityVocabUse.call(profiles: "all")
      CCU::Report::ProfileFieldsGenerator.call(
        profiles: "all",
        release: release
      )
      CCU::Report::ProfileSubjectsGenerator.call(
        profiles: "all",
        release: release
      )
      CCU::Report::ProfileStructuredDateFields.call(
        profiles: "all",
        release: release
      )
      CCU::Report::ProfileMultiAuthFields.call(
        profiles: "all",
        release: release
      )
      CCU::Report::ProfileAuthorityUse.call(
        profiles: "all",
        release: release
      )
    end

    def deversion_for_qa(row)
      fid = row["fid"]
      row["fid"] = fid.sub(/_\d+(-\d+){2}(-rc\d+|) /, " ")
      row["profile"] = row["profile"].sub(/_\d+(-\d+){2}(-rc\d+|)/, "")
      row
    end

    def get_source(default_method:, path:, default_opts: {})
      return CSV.parse(File.read(path), headers: true) if path

      CCU::Report.send(default_method, **default_opts)
    end

    def get_qa_table(release: CCU.release, prev: false)
      get_all_fields(release: release, prev: prev, outmode: :expert)
        .map { |row| deversion_for_qa(row) }
    end

    def get_all_fields(release: CCU.release, prev: false, outmode: :friendly)
      if prev
        current_release = release.dup
        CCU.config.release = CCU.prev_release
      end

      path = CCU.allfields_path(outmode: outmode)
      unless File.exist?(path)
        CCU::Report::AllFieldsGenerator.call(
          release: CCU.release,
          datemode: :collapsed,
          outmode: outmode
        )
      end

      CCU.config.release = current_release if prev

      CSV.parse(File.read(path), headers: true)
    end
  end
end
