# frozen_string_literal: true

require "cspace_config_untangler/manifest"

module CspaceConfigUntangler
  class ManifestDev < CCU::Manifest
    MapperPath = Struct.new(:profile, :rectype, :path)

    DEV_MAPPERS = {
      "anthro" => %w[collectionobject concept-associated
        chronology-field-collection],
      "fcart" => %w[collectionobject concept-associated],
      "core" => %w[collectionobject concept-associated
        chronology-event nonhierarchicalrelationship
        objecthierarchy]
    }

    private

    def create_mapper_path(path)
      splitpath = path.split("/")
      rectype = splitpath.pop.delete_suffix(".json").split("_").pop
      profile = splitpath.pop
      MapperPath.new(profile, rectype, path)
    end

    def included?(mapper)
      return false unless DEV_MAPPERS.key?(mapper.profile)
      return false unless DEV_MAPPERS[mapper.profile].any?(mapper.rectype)

      true
    end

    def mapper_paths
      mapper_paths_all.map { |path| create_mapper_path(path) }
        .select { |mapper| included?(mapper) }
        .map { |mapper| mapper.path }
    end

    def mapper_paths_all
      return Dir.glob("#{indir}/**/*.json") if recurse

      indir.children.select { |child| child.extname == ".json" }
    end
  end
end
