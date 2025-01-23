# frozen_string_literal: true

require_relative "subcommand_base"

module CspaceConfigUntangler
  module Cli
    class Fields < SubcommandBase
      desc "csv", "Write CSV containing full field data"
      long_desc <<~LONGDESC
        Output mode `expert` includes xpaths, ids, namespaces

        Output mode `friendly` omits info probably not useful for end users
      LONGDESC
      shared_options :profiles, :rectypes, :output_path, :structured_date
      shared_option :output_mode,
        enum: %w[expert friendly],
        default: "expert"
      def csv
        output = options[:output_path] || "data/fields.csv"
        CCU::Report::AllFieldsGenerator.call(
          datemode: options[:structured_date].to_sym,
          outmode: options[:output_mode].to_sym,
          profiles: options[:profiles],
          target: output
        )
      end

      desc "nonunique", "Print list of non-unique fields per profile"
      long_desc <<~LONGDESC
        Uniqueness is determined by the full XML schema, i.e. the schema_path
        plus the field name.

        The full schema_path should be unique within a record type. Non-unique
        fields are unexpected and the profile, record type, and schema path will
        be printed to the screen if any are found.
      LONGDESC
      shared_options :profiles, :rectypes
      def nonunique
        CCU::Report::NonuniqueFieldPaths.call(profiles: options[:profiles])
      end

      desc "nonunique_field_names", "Print list of non-unique field names "\
                                    "per profile"
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
      shared_options :profiles, :rectypes
      def nonunique_field_names
        CCU::Report::NonuniqueFieldNames.call(profiles: options[:profiles])
      end

      desc "unmappable", "Prints list of fields per profile that are omitted "\
           "from templates/mappers due to being unmappable"
      long_desc <<~DESC
        This is introduced because some fields are being omitted from OMCA's
        templates/mappers because they have custom namespaces in their 'contact'
        subrecord. The Untangler assumes only the common namespace is used in
        subrecords, so these fields cannot be extracted/mapped at this point.

        An unmappable field is identified by its field_mapping object having nil
        data_type and xpath attributes.
      DESC
      shared_options :profiles, :rectypes, :structured_date
      def unmappable
        get_profiles.map do |profile|
          CCU::Profile.new(
            profile: profile,
            rectypes: parse_rectypes,
            structured_date_treatment: options[:structured_date].to_sym
          ).rectypes
            .map(&:unmappable_fields)
        end
      end
    end
  end
end
