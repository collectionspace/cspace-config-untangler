# frozen_string_literal: true

module CspaceConfigUntangler
  class Manifest
    def initialize(inputdir:, output:, recursive:, type:)
      @indir = inputdir
      @output = Pathname.new(output)
      @recurse = recursive
      @type = type
    end

    def build
      File.write(output, JSON.pretty_generate(json_hash))
    end

    private

    attr_reader :indir, :output, :recurse, :type

    def json_hash
      {array_name => mapper_paths.map do |path|
        CCU::ManifestEntry.new(path: path, type: type)
      end.map(&:to_h).compact}
    end

    def array_name
      case type
      when "record type"
        "mappers"
      else
        "data configs"
      end
    end

    def mapper_paths
      return Dir.glob("#{indir}/**/*.json") if recurse

      indir.children.select { |child| child.extname == ".json" }
    end
  end
end
