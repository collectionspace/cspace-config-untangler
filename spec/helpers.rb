# frozen_string_literal: true

module Helpers
  extend self

  def fixtures
    File.join(CCU.app_dir, "spec", "fixtures")
  end

  def set_profile_release(version = "7_0")
    CCU.config.release = version
    CCU.config.mapperdir = File.join(CCU.mapperdir, "community_profiles",
      "release_#{version}")
    CCU.config.templatedir = File.join(fixtures, "files", version, "templates")
  end

  class SetupGenerator
    attr_reader :profile, :rectype
    def initialize(profile:, rectypes:, release: "7_0", dates: :collapse)
      Helpers.set_profile_release(release)
      CCU.config.main_profile_name = profile
      @profile = CCU::Profile.new(profile: CCU.main_profile,
        rectypes: rectypes, structured_date_treatment: dates)
      @rectype = @profile.rectypes.first
    end

    def extension(ext_name)
      CCU::Extension.new(profile, ext_name)
    end

    def field(rectype, fieldname)
      profile.fields.find { |field|
        field.rectype.name == rectype && field.name == fieldname
      }
    end

    def field_def_config(namespace)
      parser = field_def_parser

      CCU::Fields::Def::Config.new(
        rectype: rectype,
        namespace: namespace,
        field_hash: parser.config[namespace],
        parser: parser
      )
    end

    def field_def_hash
      @field_def_hash ||= rectype.config["fields"]["document"]
    end

    def field_def_parser
      @field_def_parser ||= CCU::Fields::Def::Parser.new(rectype,
        field_def_hash)
    end

    def form(template = "default")
      rectype.forms[template]
    end

    def namespace_field_parser(namespace, config = nil)
      cfg = config || field_def_config(namespace)
      CCU::Fields::Def::NamespaceFieldParser.new(cfg)
    end

    def record_mapping(subtype = nil)
      CCU::RecordMapper::RecordMapping.new(profile: profile, rectype: rectype,
        subtype: subtype)
    end

    def template_file
      csv = CSV.parse(File.read(template_file_path), headers: false)
      csv.shift
      csv.transpose
    end

    def template_object(type = "displayname")
      CCU::Template::CsvTemplate.new(profile: profile, rectype: rectype,
        type: type)
    end

    def template_testable(type = "displayname")
      csv = template_object(type).csvdata
      csv.shift
      csv.transpose
    end

    private

    def template_file_path
      Pathname.new(File.join(CCU.templatedir, CCU.main_profile_name))
        .children
        .find { |filename| filename.to_s["_#{rectype.name}-template"] }
    end
  end
end
