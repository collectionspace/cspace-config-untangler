module CspaceConfigUntangler
  class StructuredDateMessageGetter
    def initialize(profileobj)
      @profile = profileobj
      @config = @profile.config['extensions']['structuredDate']['fields']
      @fields = @config.keys
      set_messages
    end

    private

    def set_messages
      @fields.each{ |field|
        id = "field.ext.structuredDate.#{field}"
        name = @config.dig(field, '[config]', 'messages', 'fullName',
                           'defaultMessage')
        fullName = @config.dig(field, '[config]', 'messages', 'fullName',
                               'defaultMessage')
        fullName = fix_labels(field) if fullName.nil?
        @profile.messages[id] = {'name' => name, 'fullName' => fullName}
      }
    end

    def fix_labels(fieldname)
      case fieldname
      when 'dateDisplayDate'
        return ''
      when 'datePeriod'
        return 'Period'
      when 'dateAssociation'
        return 'Association'
      when 'dateNote'
        return 'Note'
      when 'dateEarliestSingleDay'
        return 'Earliest/Single day'
      when 'dateEarliestSingleMonth'
        return 'Earliest/Single month'
      when 'dateEarliestSingleQualifier'
        return 'Earliest/Single qualifier'
      when 'dateEarliestSingleQualifierValue'
        return 'Earliest/Single value'
      when 'dateEarliestSingleYear'
        return 'Earliest/Single year'
      when 'dateEarliestScalarValue'
        return 'Earliest/Single scalar value'
      when 'dateLatestDay'
        return 'Latest day'
      when 'dateLatestMonth'
        return 'Latest month'
      when 'dateLatestQualifier'
        return 'Latest qualifier'
      when 'dateLatestQualifierValue'
        return 'Latest value'
      when 'dateLatestYear'
        return 'Latest year'
      when 'dateLatestScalarValue'
        return 'Latest scalar value'
      when 'scalarValuesComputed'
        return 'Scalar values computed?'
      end
    end
  end #class
end #module
