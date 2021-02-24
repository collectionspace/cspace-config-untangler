require 'cspace_config_untangler'

module CspaceConfigUntangler
  module JsonWritable
      def to_json(data:, output: )
        File.open(output, 'w') do |f|
          f.write(JSON.pretty_generate(data))
        end
      end
  end
end
