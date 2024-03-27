module CspaceConfigUntangler
  module JsonWritable
    def to_json(data:, output:)
      File.write(output, JSON.pretty_generate(data))
    end
  end
end
