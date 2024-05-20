# frozen_string_literal: true

module CspaceConfigUntangler
  module Forms
    # Each form/template is a gigantic, hideously nested JSON object.
    # This class represents a nested `props` object in this mess,
    # exposing the known and calculated properties at that level, so
    # we can work with them
    class Props
      NS_MATCHER = /^(?:ns2:|ext\.)/

      # name values that are not appended to ui/xml path
      NON_PATH_NAMES = %w[document propsHolder childHolder nameless].freeze

      attr_reader :form, :config, :parent, :ancestors,
        :keys, :rectype, :profile, :name, :is_panel, :panel,
        :ns, :ns_for_id, :ui_path,
        :repeats, :in_repeating_group,
        :warnings, :errors

      # @param form [CCU::Forms::Form]
      # @param validator [CCU::Forms::PropsValidator]
      # @param config [Hash]
      # @param parent [nil, CCU::Forms::Props]
      def initialize(form, validator, config, parent = nil)
        @form = form
        @validator = validator
        @config = config
        @keys = config.keys.sort
        @subpath = config["subpath"]
        @parent = parent
        @ancestors = get_ancestors
        @rectype = form.rectype
        @profile = rectype.profile
        @name = get_name
        @is_panel = rectype.panels.include?(name)
        @panel = get_panel
        @ns = get_ns
        @ns_for_id = get_ns_for_id
        @ui_path = populate_ui_path
        @repeats = get_repeats
        @in_repeating_group = get_in_repeating_group
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

      def treatment
        return :subrecord if subrecord?
        return :field if field?
        return :props if keys == %w[_owner key props ref] ||
          keys == %w[_owner key props ref type]
        return :content_free_parent if content_free_has_children

        :content_bearing_parent if content_bearing_has_children
      end

      def warning_id
        "#{form.id} #{formatted_ui_path}"
      end

      def formatted_ui_path
        ui_path.join(" / ")
      end

      def skippable?
        return true if name == "hierarchy"
        return true if name == "relation-list-item"
        return true if bad_material_public_template_field?
        return true if keys == ["style"]
        return true if keys == %w[defaultMessage id values]
        return true if keys == %w[name showDetachButton]
        return true if core?

        false
      end

      def to_s
        parts = [profile.name, rectype.name, "#{form.name} form",
          formatted_ui_path, name].compact.join(" / ")

        "<##{self.class}:#{object_id.to_s(8)} #{parts}>"
      end
      alias_method :inspect, :to_s

      protected

      def address?
        return true if parent&.address?

        true if name == "addrGroupList"
      end

      def blob? = name == "blob" && profile.extensions.include?(name)

      def children? = config.key?("children")

      def contact?
        return false if ns == "ns2:acquisitions_omca"

        name == "contact" && profile.extensions.include?(name)
      end

      def core? = ns == "ns2:collectionspace_core"

      def extension?
        return false unless is_panel

        profile.extensions.include?(name)
      end

      def measurement?
        return true if name == "measuredPartGroupList"

        true if parent&.measurement?
      end

      def input_table?
        true if children? && rectype.input_tables.key?(name)
      end

      def subrecord? = blob? || contact?

      private

      attr_reader :subpath, :validator, :validated

      def get_ancestors
        if parent
          parent.ancestors.clone + [parent]
        else
          []
        end
      end

      def get_name
        return config["name"] if config.key?("name")
        return "propsHolder" if config.key?("props")
        return "childHolder" if config.key?("children")

        "nameless"
      end

      def get_panel
        return "panel.#{rectype.name}.#{name}" if is_panel
        return parent.panel if parent

        nil
      end

      def get_ns
        return subpath_ns if subpath_ns
        return parent.ns if parent

        rectype.ns
      end

      def get_ns_for_id
        return parent.ns_for_id if parent&.ns_for_id &&
          parent.ns_for_id.start_with?("ext.")
        return "ext.associatedAuthority" if name == "authorities"
        return "ext.dimension" if measurement?
        return "ext.address" if address? && !contact?

        lkup = CCU::Fields::Definition::Namespace::FOR_ID_BY_LITERAL
        return lkup[ns] if lkup.key?(ns)

        if ns == "ns2:collectionobjects_variablemedia" &&
            !NON_PATH_NAMES.include?(name)
          if name.start_with?("contentWork")
            return "ext.contentWorks"
          else
            return "ext.technicalSpecs"
          end
        end
        return "ext.technicalChanges" if ns ==
          "ns2:conditionchecks_variablemedia"

        if (ns == "ns2:persons_publicart" ||
            ns == "ns2:organizations_publicart") &&
            name.start_with?("socialMedia")
          return "ext.socialMedia"
        end
        return "ext.locality" if name.start_with?("localityGroup")

        ns
      end

      def field?
        return true if bad_work_date?
        return false if children?

        keysigs = [
          %w[name],
          %w[name subpath],
          %w[embedded label name]
        ]

        true if keysigs.include?(keys)
      end

      def content_free_has_children
        keysigs = [
          %w[children],
          %w[children style]
        ]

        true if keysigs.include?(keys)
      end

      def content_bearing_has_children
        keysigs = [
          %w[children name],
          %w[children collapsed collapsible name],
          %w[children collapsible name],
          %w[children name subpath],
          %w[children subpath tabular],
          %w[children name tabular]
        ]

        true if keysigs.include?(keys)
      end

      def populate_ui_path
        return [] if skippable?

        path = initial_ui_path
        return path if NON_PATH_NAMES.include?(name) ||
          bad_work_date? ||
          field_array_subpath?

        append_to_ui_path(path)
        path
      end

      def initial_ui_path
        return parent.ui_path.clone if parent

        []
      end

      def append_to_ui_path(path)
        if input_table?
          path << rectype.input_tables[name]
        elsif is_panel
          path << panel
        elsif children? && !name.empty?
          path << "#{ns&.sub("ns2:", "")}.#{name}"
        end
      end

      def field_array_subpath?
        subpath&.is_a?(Array) && field? && namespace_str?(subpath[0])
      end

      # rubocop:disable Performance/InefficientHashSearch
      # These usages of `keys.include?` are not on a Hash.
      def embedded_field?
        keys.include?("embedded") &&
          config["embedded"] == true &&
          ancestors.any? do |anc|
            anc.keys.include?("tabular") &&
              anc.config["tabular"] == false
          end
      end
      # rubocop:enable Performance/InefficientHashSearch

      def subpath_ns
        return nil unless subpath

        case subpath.class.name
        when "String"
          if namespace_str?
            subpath
          else
            CCU.log.warn("FORM SUBPATH: non-namespace string: #{config}")
          end
        when "Array"
          result = subpath.find { |val| namespace_str?(val) }
          if result.empty?
            CCU.log.warn("FORM SUBPATH: array with no namespace: #{config}")
          else
            result
          end
        else
          CCU.log.warn("FORM SUBPATH: unknown structure: #{config}")
        end
      end

      def namespace_str?(val = subpath) = val.match?(NS_MATCHER)

      def get_repeats
        return "n" if field_array_subpath? && subpath[-1] == "0"

        "y" if embedded_field?
      end

      def get_in_repeating_group
        "n" if field_array_subpath? || embedded_field?
      end

      # Prior to 6.1, the form output in the config included "workDate" as a
      # child under "workDateGroup", though "workDate" was not output as a
      # field definition in the fields section of the config. The issue remains
      # in the default works form in publicart
      def bad_work_date?
        rectype.name == "work" &&
          name == "workDateGroup" &&
          children?
      end

      def bad_material_public_template_field?
        CCU.upgrade_warner.call(target_version: "8_1", issue: "DRYD-1419")

        profile.name.start_with?("materials") &&
          rectype.name == "collectionobject" &&
          form.name == "public"
      end
    end
  end
end
