# frozen_string_literal: true

module CspaceConfigUntangler
  module Forms
    # Each form/template is a gigantic, hideously nested JSON object.
    # This class represents a nested `props` object in this mess,
    # exposing the known and calculated properties at that level, so
    # we can work with them
    class Props
      attr_reader :form, :config, :parent,
                  :keys, :rectype, :profile, :name, :ui_path,
                  :warnings, :errors

      # @param form [CCU::Forms::Form]
      # @param validator [CCU::Forms::PropsValidator]
      # @param config [Hash]
      # @param parent [nil, ?]
      def initialize(form, validator, config, parent = nil)
        @form = form
        @validator = validator
        @config = config
        @keys = config.keys.sort
        @parent = parent
        @rectype = form.rectype
        @profile = rectype.profile
        @name = get_name
        @ui_path = populate_ui_path
        @warnings = []
        @errors = []
        @validated = false
      end

      def add_warning(warning) = @warnings << warning

      def add_error(error) = @errors << error

      def valid?
        unless validated
          validator.call(self)
          @validated = true
        end

        true if errors.empty?
      end

      def address?
        return true if parent? && parent.address?

        true if name == 'addrGroupList'
      end

      def blob? = name == 'blob' && profile.extensions.include?(name)

      def children? = config.key?('children')

      def contact?
        return false if ns == 'ns2:acquisitions_omca'

        name == 'contact' && profile.extensions.include?(name)
      end

      def core? = ns == 'ns2:collectionspace_core'

      def extension?
        return false unless panel?

        profile.extensions.include?(name)
      end

      def ns
        return subpath_ns if subpath_ns

        parent? ? parent.ns : rectype.ns
      end

      def ns_for_id
        return parent.ns_for_id if parent &&
                                   parent.ns_for_id &&
                                   parent.ns_for_id.start_with?('ext.')

        return 'ext.measurement' if measurement?
        return 'ext.address' if address? && !contact?

        return 'ext.accessionattributes' if ns ==
                                            'ns2:collectionobjects_accessionattributes'
        return 'ext.accessionuse' if ns == 'ns2:collectionobjects_accessionuse'
        return 'ext.fineart' if ns == 'ns2:collectionobjects_fineart'
        return 'ext.commission' if ns == 'ns2:acquisitions_commission'

        if ns == 'ns2:collectionobjects_variablemedia'
          return 'ext.contentWorks' if name.start_with?('contentWork')

          return 'ext.technicalSpecs'

        end
        return 'ext.technicalChanges' if ns ==
                                         'ns2:conditionchecks_variablemedia'

        if (ns == 'ns2:persons_publicart' || ns == 'ns2:organizations_publicart') && name.start_with?('socialMedia')
          return 'ext.socialMedia'
        end
        return 'ext.locality' if name.start_with?('localityGroup')

        ns
      end

      def panel
        return "panel.#{rectype.name}.#{name}" if panel?
        return parent.panel if parent?

        ''
      end

      def panel?
        return false if parent? && parent.panel?

        rectype.panels.include?(name)
      end

      def parent? = parent ? true : false

      def measurement?
        return true if name == 'measuredPartGroupList'

        true if parent? && parent.measurement?
      end

      def treatment
        return :subrecord if subrecord?
        return :field if field?
        return :props if keys == %w[_owner key props ref] ||
                         keys == %w[_owner key props ref type]
        return :content_free_parent if content_free_parent?

        :content_bearing_parent if content_bearing_parent?
      end

      def subrecord? = blob? || contact?

      def warning_id
        "#{form.id} #{formatted_ui_path}"
      end

      def formatted_ui_path
        ui_path.join(' / ')
      end

      def skippable?
        return true if name == 'hierarchy'
        return true if name == 'relation-list-item'
        return true if keys == ['style']
        return true if keys == %w[defaultMessage id values]
        return true if keys == %w[name showDetachButton]
        return true if core?

        false
      end

      def to_s
        parts = [profile.name, rectype.name, "#{form.name} form",
                 formatted_ui_path, name].compact.join(' / ')

        "<##{self.class}:#{object_id.to_s(8)} #{parts}>"
      end
      alias inspect to_s

      private

      attr_reader :validator, :validated

      def get_name
        return config['name'] if config.key?('name')
        return 'propsHolder' if config.key?('props')
        return 'childHolder' if config.key?('children')

        'nameless'
      end

      def field?
        keysigs = [
          %w[name],
          %w[name subpath],
          %w[embedded label name]
        ]

        true if bad_work_date? || keysigs.include?(keys)
      end

      def content_free_parent?
        keysigs = [
          %w[children],
          %w[children style]
        ]

        true if keysigs.include?(keys)
      end

      def content_bearing_parent?
        keysigs = [
          %w[children name],
          %w[children collapsed collapsible name],
          %w[children collapsible name],
          %w[children name subpath],
          %w[children subpath tabular],
          %w[childen name tabular]
        ]

        true if keysigs.include?(keys)
      end

      def populate_ui_path
        return [] if skippable?

        path = initial_ui_path
        return path if name == 'document'
        return path if panel? && !parent?

        append_to_ui_path(path)
        path
      end

      def initial_ui_path
        if field_specific_subpath?
          # binding.pry
        elsif parent?
          parent.ui_path.clone
        else
          []
        end
      end

      def append_to_ui_path(path)
        if input_table?
          path << rectype.input_tables[name]
        elsif panel?
          path << panel
        elsif children? && !name.empty?
          path << "#{ns&.sub('ns2:', '')}.#{name}"
        end
      end

      def field_specific_subpath?
        !children? &&
          !config.key?('props') &&
          config.key?('subpath') &&
          config['subpath'].is_a?(Array)
      end

      def input_table?
        true if children? && rectype.input_tables.key?(name)
      end

      def subpath_ns
        return nil unless config.key?('subpath')

        subpath = config['subpath']
        case subpath.class.name
        when 'String'
          if subpath?(subpath)
            subpath
          else
            binding.pry
            CCU.log.warn("FORM SUBPATH: non-namespace string: #{config}")
          end
        when 'Array'
          result = subpath.find { |val| subpath?(val) }
          if result.empty?
            CCU.log.warn("FORM SUBPATH: array with no namespace: #{config}")
          else
            result
          end
        else
          CCU.log.warn("FORM SUBPATH: unknown structure: #{config}")
        end
      end

      def subpath?(val) = val.match?(/^(?:ns2:|ext\.)/)

      # Prior to 6.1, the form output in the config included "workDate" as a
      # child under "workDateGroup", though "workDate" was not output as a
      # field definition in the fields section of the config
      def bad_work_date?
        true if CCU.release.lt('6_1') &&
                rectype == 'work' &&
                name == 'workDateGroup'
      end
    end
  end
end
