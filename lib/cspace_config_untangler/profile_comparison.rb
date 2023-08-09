module CspaceConfigUntangler
  class ProfileComparison
    attr_reader :output
    def initialize(profilearray, outputdir)
      profiles = profilearray.map{ |p| CCU::Profile.new(profile: p) }
      @profiles = profiles.map{ |p| p.name }
      @output = "#{outputdir}/compare_#{@profiles[0]}_to_#{@profiles[1]}.csv"
      @fields = profiles.map{ |p| p.fields.map{ |f| f.clean} }.map{ |p| by_path(p) }
      @combined = combined_fields
      @diff = diff_combined
    end

    def write_csv
      fields = diffed_fields
      headers = fields.first.csv_header
      headers << 'diff info'

      CSV.open(@output, 'w', write_headers: true, headers: headers){ |csv|
        fields.each{ |f| csv << f.to_csv }
      }
    end

    def summary
      @diff.map{ |k, arr| "#{k}: #{arr.size}" }.join("\n")
    end

    private

    def diffed_fields
      diff_fields = []

      @diff.each do |type, val|
        if type['not in']
          # val is an array of field objects
          val.each do |f|
            f.to_csv << type
            diff_fields << f
          end
        elsif type == 'same'
          # val is array of hashes of two field objects { 0 => fieldobj, 1 => fieldobj }
          val.each do |h|
            h.each_value{ |f| diff_fields << f }
          end
        else
          # val is array of hashes of two field objects { 0 => fieldobj, 1 => fieldobj }
          val.each do |h|
            h.each_value do |f|
              f.to_csv << type
              diff_fields << f
            end
          end
        end
      end

      return diff_fields
    end


    def diff_combined
      diff = {
        "not in #{@profiles[0]}" => [],
        "not in #{@profiles[1]}" => [],
        'source differences' => [],
        'ui path differences' => [],
        'same' => []
      }

      @combined.each{ |id, hash|
        if hash[0].nil?
          diff["not in #{@profiles[0]}"] << hash[1]
        elsif hash[1].nil?
          diff["not in #{@profiles[1]}"] << hash[0]
        elsif hash[0].value_source&.sort != hash[1].value_source&.sort
          diff['source differences'] << hash
        elsif hash[0].ui_path != hash[1].ui_path
          diff['ui path differences'] << hash
        else
          diff['same'] << hash
        end
      }

      return diff
    end

    def combined_fields
      h = {}
      @fields.each{ |fhash| fhash.keys.each{ |k| h[k] = { 0 => nil, 1 => nil } } }
      @fields.each_with_index{ |fhash, i|
        fhash.each{ |path, f|
          h[path][i] = f
        }
      }
      return h
    end

    # receives field_defs hash
    # returns has by rectype + schema path + name
    def by_path(field_arr)
      h = {}
      field_arr.each{ |f|
        path = [f.rectype, f.schema_path, f.name].flatten
          h[path] = f
        }
      return h
    end

  end #class ProfileComparison
end #module
