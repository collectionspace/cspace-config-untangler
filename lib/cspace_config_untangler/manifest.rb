module CspaceConfigUntangler
  class Manifest
    def initialize(inputdir:, output:, recursive:)
      @indir = inputdir
      @output = Pathname.new(output)
      @recurse = recursive
    end

    def build
      File.write(output, JSON.pretty_generate(json_hash))
    end

    private

    attr_reader :indir, :output, :recurse

    def json_hash
      {"mappers" => mapper_paths.map { |path|
                      CCU::ManifestEntry.new(path: path)
                    }.map(&:to_h).compact}
    end

    def mapper_paths
      return Dir.glob("#{indir}/**/*.json") if recurse

      indir.children.select { |child| child.extname == ".json" }
    end
  end
end
