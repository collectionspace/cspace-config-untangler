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

      def children? = config.key?("children")

      def contact? = name == "contact" && profile.extensions.include?(name)

      def panel
        return parent.panel if parent?
        return "panel.#{rectype.name}.#{name}" if panel?

        ""
      end

      def panel? = rectype.panels.include?(name)

      def parent? = parent ? true : false

      # @todo test
      def measurement?
        true if name == "measuredPartGroupList"
        true if parent? && parent.measurement?
      end

      def warning_id
        "#{form.id} #{formatted_ui_path}"
      end

      def formatted_ui_path
        ui_path.join(" / ")
      end

      def namespace
        ""
      end
      alias_method :ns, :namespace

      # Prior to 6.1, the form output in the config included "workDate" as a
      # child under "workDateGroup", though "workDate" was not output as a
      # field definition in the fields section of the config
      def bad_work_date?
        true if CCU.release.version.lt("6_1") &&
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
    end
  end
end
