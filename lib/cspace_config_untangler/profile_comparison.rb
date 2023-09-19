module CspaceConfigUntangler
  class ProfileComparison
    attr_reader :output
    def initialize(profilearray, outputdir)
      @profilenames = profilearray
      @profiles = profilearray.map do |p|
        CCU::Profile.new(profile: p, structured_date_treatment: :collapse)
      end
      @output = "#{outputdir}/compare_#{profilenames[0]}_to_#{profilenames[1]}.csv"
      @fields = profiles.map { |profile| by_path(profile.fields) }
      @combined = combined_fields
      @diff = {
        "not in #{profilenames[0]}" => [],
        "not in #{profilenames[1]}" => [],
        "source differences" => [],
        "ui path differences" => [],
        "same" => []
      }
      populate_diff
    end

    def write_csv
      fields = diffed_fields
      headers = fields.first.keys

      CSV.open(@output, "w", write_headers: true, headers: headers) { |csv|
        fields.each { |f| csv << f.values_at(*headers) }
      }
    end

    def summary
      @diff.map { |k, arr| "#{k}: #{arr.size}" }.join("\n")
    end

    private

    attr_reader :profilenames, :profiles, :fields, :diff

    def diffed_fields
      diff_fields = []

      @diff.each do |type, val|
        if type["not in"]
          # val is an array of field objects
          val.each do |f|
            diff_fields << f.to_h.merge({"diff_info" => type})
          end
        elsif type == "same"
          # val is array of hashes of two field objects
          #   { 0 => fieldobj, 1 => fieldobj }
          val.each do |h|
            h.each_value { |f| diff_fields << f.to_h }
          end
        else
          # val is array of hashes of two field objects
          #   { 0 => fieldobj, 1 => fieldobj }
          val.each do |h|
            h.each_value do |f|
              diff_fields << f.to_h.merge({"diff_info" => type})
            end
          end
        end
      end

      diff_fields
    end

    def populate_diff
      @combined.each { |id, hash|
        if hash[0].nil? && hash[1]
          cat = "not in #{profilenames[0]}"
          diff[cat] << hash[1]
        elsif hash[0] && hash[1].nil?
          cat = "not in #{profilenames[1]}"
          diff[cat] << hash[0]
        elsif hash[0].value_source&.sort != hash[1].value_source&.sort
          cat = "source differences"
          diff[cat] << hash
        elsif hash[0].ui_path != hash[1].ui_path
          cat = "ui path differences"
          diff[cat] << hash
        else
          diff["same"] << hash
        end
      }

      diff
    end

    def combined_fields
      h = {}
      @fields.each { |fhash|
        fhash.keys.each { |k|
          h[k] = {0 => nil, 1 => nil}
        }
      }
      @fields.each_with_index { |fhash, i|
        fhash.each { |path, f|
          h[path][i] = f
        }
      }
      h
    end

    # receives field_defs hash
    # returns has by rectype + schema path + name
    def by_path(field_arr)
      field_arr.map { |f|
        path = [f.rectype.name, f.schema_path, f.name].flatten
        [path, f]
      }.to_h
    end
  end
end
