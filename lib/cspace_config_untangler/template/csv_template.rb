# frozen_string_literal: true

module CspaceConfigUntangler
  module Template
    class CsvTemplate
      ::CsvTemplate = CspaceConfigUntangler::Template::CsvTemplate
      attr_reader :csvdata

      # profile = CCU::Profile
      # rectype = CCU::RecordType
      def initialize(profile:, rectype:, type:)
        @profile = profile
        @rectype = rectype
        @type = type
        @config = @profile.config
        @mappings = @rectype.batch_mappings(:template).map(&:to_h)
        if @type == "displayname"
          @mappings = @mappings.reject do |mapping|
                        mapping[:data_type] == "csrefname"
                      end
            .reject do |mapping|
              mapping.key?(:to_template) && mapping[:to_template] == false
          end
        elsif @type == "refname"
          @mappings = @mappings.reject do |mapping|
            mapping[:source_type].match?(/authority|vocabulary/) &&
              mapping[:data_type] == "string"
          end
        end
        @csvdata = []
        build_template
      end

      def filename
        stubname = "#{@profile.name}_#{@rectype.name}"
        return "#{stubname}-refnames-template.csv" if @type == "refname"

        "#{stubname}-template.csv"
      end

      def write(dir)
        path = "#{File.expand_path(dir)}/#{filename}"
        CSV.open(path, "wb") do |csv|
          @csvdata.each { |r| csv << r }
        end
      end

      private

      def build_template
        requiredfields = @mappings.select { |m| m[:required].start_with?("y") }
        otherfields = @mappings.select { |m| m[:required] == "n" }
        instruct = ["Before importing CSV, delete initial column and rows "\
                    "above the CSVHEADER row"]
        required = ["REQUIRED"]
        datatype = ["DATA TYPE"]
        repeats = ["REPEATABLE FIELD?"]
        group = ["REPEATING FIELD GROUP"]
        sourcetype = ["VALUE SOURCE TYPE"]
        source = ["VALUE SOURCE"]
        headers = ["CSVHEADER"]

        [requiredfields, otherfields].each do |fieldmappings|
          fieldmappings.each do |mapping|
            instruct << ""
            required << mapping[:required].sub(" in template", "")
            datatype << mapping[:data_type]
            repeats << mapping[:repeats]
            group << if mapping[:in_repeating_group].start_with?("n")
              ""
            else
              mapping[:xpath].join(" < ")
            end
            sourcetype << mapping[:source_type]
            source << case mapping[:source_type]
            when "optionlist"
              mapping[:opt_list_values].join(", ")
            when "authority"
              mapping[:source_name]
            when "vocabulary"
              mapping[:source_name]
            when "csrefname"
              mapping[:source_name]
            else
              ""
            end

            headers << mapping[:datacolumn]
          end
        end

        @csvdata << instruct
        @csvdata << required
        @csvdata << datatype
        @csvdata << repeats
        @csvdata << group
        @csvdata << sourcetype
        @csvdata << source
        @csvdata << headers
      end
    end
  end
end
