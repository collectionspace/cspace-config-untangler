# frozen_string_literal: true

module CspaceConfigUntangler
  module Forms
    # Each form/template is a gigantic, hideously nested JSON object.
    # This class represents a nested `props` object in this mess,
    # exposing the known and calculated properties at that level, so
    # we can work with them
    class Props
      attr_reader :config

      # @param form [CCU::Forms::Form]
      # @param config [Hash]
      # @param parent [nil, ?]
      def initialize(form, config, parent = nil)
        @form = form
        @config = config
        @parent = parent
        @rectype = form.rectype
        @profile = rectype.profile

        @name = config.key?("name") ? config["name"] : ""
        @ui_path = parent? ? parent.ui_path.clone : []
        append_to_ui_path
      end

      def address?
        true if parent? && parent.address?
        true if name == "addrGroupList"
      end

      def blob? = name == "blob" && profile.extensions.include?(name)

      def children? = config.key?("children")

      def contact? = name == "contact" && profile.extensions.include?(name)

      def core? = ns == "ns2:collectionspace_core"

      def extension?
        return false unless panel?

        profile.extensions.include?(name)
      end

      def ns
        return subpath_ns if subpath_ns

        parent? ? parent.ns : rectype.ns
      end

      def ns_for_id
        return parent.ns_for_id if parent && parent.ns_for_id &&
          parent.ns_for_id.start_with?("ext.")

        return "ext.measurement" if measurement?

        "foo"
      end

      def panel
        return parent.panel if parent?
        return "panel.#{rectype.name}.#{name}" if panel?

        ""
      end

      def panel? = rectype.panels.include?(name)

      def parent? = parent ? true : false

      # @todo test
      def measurement?
        true if (name == "measuredPartGroupList") ||
          (parent? && parent.measurement?)
      end

      def warning_id
        "#{form.id} #{formatted_ui_path}"
      end

      def formatted_ui_path
        ui_path.join(" / ")
      end

      # Prior to 6.1, the form output in the config included "workDate" as a
      # child under "workDateGroup", though "workDate" was not output as a
      # field definition in the fields section of the config
      def bad_work_date?
        true if CCU.release.lt("6_1") &&
          rectype == "work" &&
          name == "workDateGroup"
      end

      protected

      attr_reader :ui_path

      private

      attr_reader :form, :parent,
        :rectype, :profile, :name

      def append_to_ui_path
        return if name == "document"
        return if panel? && !parent?

        if input_table?
          ui_path << rectype.input_tables[name]
        elsif panel?
          ui_path << panel
        elsif children? && !name.empty?
          ui_path << "#{ns&.sub("ns2:", "")}.#{name}"
        end
      end

      def input_table?
        true if children? && rectype.input_tables.key?(name)
      end

      def subpath_ns
        return nil unless config.key?("subpath")

        subpath = config["subpath"]
        case subpath.class.name
        when "String"
          if subpath?(subpath)
            subpath
          else
            CCU.log.warn("FORM SUBPATH: non-namespace string: #{config}")
          end
        when "Array"
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
    end
  end
end
