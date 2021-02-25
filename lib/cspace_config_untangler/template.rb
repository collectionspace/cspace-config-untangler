require 'cspace_config_untangler'

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
        @mappings = @rectype.batch_mappings.map(&:to_h)
        if @type == 'displayname'
          @mappings = @mappings.reject{ |mapping| mapping[:data_type] == 'csrefname' }
            .reject{ |mapping| mapping.key?(:to_template) && mapping[:to_template] == false }
        elsif @type == 'refname'
          @mappings = @mappings.reject do |mapping|
            mapping[:source_type].match?(/authority|vocabulary/) && mapping[:data_type] == 'string'
            end
        end
        @csvdata = []
        build_template
      end

      def write(dir)
        stubname = "#{@profile.name}_#{@rectype.name}"
        filename = @type == 'refname' ? "#{stubname}-refnames-template.csv" : "#{stubname}-template.csv"
        path = "#{File.expand_path(dir)}/#{filename}"
        CSV.open(path, 'wb') do |csv|
          @csvdata.each{ |r| csv << r }
        end
      end

      private

      def build_template
        requiredfields = @mappings.select{ |m| m[:required] == 'y' }
        otherfields = @mappings.select{ |m| m[:required] == 'n' }
        instruct = ['Before importing CSV, delete initial column and rows above the CSVHEADER row']
        required = ['REQUIRED']
        datatype = ['DATA TYPE']
        repeats = ['REPEATABLE FIELD?']
        group = ['REPEATING FIELD GROUP']
        sourcetype = ['VALUE SOURCE TYPE']
        source = ['VALUE SOURCE']
        headers = ['CSVHEADER']
        
        [requiredfields, otherfields].each do |fieldmappings|
          fieldmappings.each do |mapping|
            instruct << ''
            required << mapping[:required]
            datatype << mapping[:data_type]
            repeats << mapping[:repeats]
            mapping[:in_repeating_group].start_with?('n') ? group << '' : group << mapping[:xpath].join(' < ')
            sourcetype << mapping[:source_type]
            case mapping[:source_type]
            when 'optionlist'
              source << mapping[:opt_list_values].join(', ')
            when 'authority'
              source << mapping[:source_name]
            when 'vocabulary'
              source << mapping[:source_name]
            when 'csrefname'
              source << mapping[:source_name]
            else
              source << ''
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
end #module
