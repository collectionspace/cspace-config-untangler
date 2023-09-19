require_relative 'helpers'

module CspaceConfigUntangler
  module Cli
    class FieldsCli < Thor
      include CCU::Cli::Helpers

      desc 'csv', 'Write CSV containing full field data'
      option :output,
             desc: 'Path to output file',
             default: 'data/fields.csv',
             aliases: '-o',
             type: :string
      option :structured_date,
             desc: 'expanded: report all individual structured date fields; '\
                   'collapsed: report the parent of individual structured '\
                   'date fields as the field',
             default: 'expanded',
             aliases: '-d',
             type: :string
      option :output_mode,
             desc: 'expert: xpaths, ids, machine names; friendly: omit expert '\
                   'stuff not useful for CSV Importer use',
             default: 'expert',
             aliases: '-m',
             type: :string
      def csv
        CCU::Report::AllFieldsGenerator.call(
          datemode: options[:structured_date].to_sym,
          outmode: options[:output_mode].to_sym,
          profiles: options[:profiles],
          target: options[:output]
        )
      end

      desc 'nonunique', 'Print list of non-unique fields per profile'
      long_desc <<~LONGDESC
        Uniqueness is determined by the full XML schema, i.e. the schema_path
        plus the field name.

        The full schema_path should be unique within a record type. Non-unique
        fields are unexpected and the profile, record type, and schema path will
        be printed to the screen if any are found.
  LONGDESC
      def nonunique
        CCU::Report::NonuniqueFieldPaths.call(profiles: options[:profiles])
      end

      desc 'nonunique_field_names', 'Print list of non-unique field names '\
                                    'per profile'
      long_desc <<~LONGDESC
        This reports fields in the same record type that have the same
        underlying field name, without consideration of the full XML schema path
        of the field.

        While these field names will work ok if they have different namespaces/
        xpaths, they are confusing when we need to discuss what fields to
        change, relabel, report on, update, or remove.

        Known/legacy duplicates are shown separately, since it's difficult to
        change them. Look out for new ones and don't let them in, if possible!
      LONGDESC
      def nonunique_field_names
        CCU::Report::NonuniqueFieldNames.call(profiles: options[:profiles])
      end

      desc 'unmappable', 'Prints list of fields per profile that are omitted '\
           'from templates/mappers due to being unmappable'
      long_desc <<~DESC
        This is introduced because some fields are being omitted from OMCA's
        templates/mappers because they have custom namespaces in their 'contact'
        subrecord. The Untangler assumes only the common namespace is used in
        subrecords, so these fields cannot be extracted/mapped at this point.

        An unmappable field is identified by its field_mapping object having nil
        data_type and xpath attributes.
      DESC
      option :rectypes,
             desc: "Comma separated list (no spaces) of record types to "\
                   "include. Defaults to all.",
             default: "all",
             aliases: "-r"
      option :structured_date,
             desc: "explode: report all individual structured date fields; "\
                   "collapse: report the parent of individual structured date "\
                   "fields as the field",
             default: "explode",
             aliases: "-d"
      def unmappable
        rt = options[:rectypes] == 'all' ? [] : options[:rectypes].split(',')
        get_profiles.each do |profile|
          profile_obj = CCU::Profile.new(
            profile: profile,
            rectypes: rt,
            structured_date_treatment: options[:structured_date].to_sym
          )
          profile_obj.rectypes.each{ |rt| rt.unmappable_fields }
        end
      end
    end
  end
end
