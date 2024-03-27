require_relative "children"
require_relative "field"

module CspaceConfigUntangler
  module Forms
    class Properties
      attr_reader :form, :parent,
        :panel, :name, :ui_path, :ns, :ns_for_id, :is_panel, :is_ext,
        :is_measurement, :is_address, :is_contact, :parent

      def initialize(formobj, hash, parent = nil)
        @form = formobj
        @hash = hash
        @parent = parent
        @name = get_name
        @is_panel = @form.rectype.panels.include?(@name)
        @is_ext = if @is_panel
          @form.rectype.profile.extensions.include?(@name)
        else
          false
        end
        @is_measurement = is_measurement?
        @is_address = is_address?
        @is_contact = false
        @is_blob = false
        # We only want top-level panels to be treated as such in the
        #   human-readable CSVs
        @panel = if @is_panel && @parent
          @parent.panel
        else
          get_panel_id
        end
        @ns = get_ns
        @ns_for_id = get_ns_for_id
        @ui_path = build_ui_path

        if @ns == "ns2:collectionspace_core"
          # skip
        elsif @hash.dig("children")
          # this catches a form field whose child field is not defined as a field
          if @ns == "ns2:works_common" && @name == "workDateGroup"
            @form.fields << CCU::Forms::Field.new(self)
          else
            CCU::Forms::Children.new(@form, self, @hash["children"])
          end
        elsif @name == "contact" && @form.rectype.profile.extensions.include?(@name)
          @is_contact = true
          process_subrecord("contact", "default")
        elsif @name == "blob" && @form.rectype.profile.extensions.include?(@name)
          @is_blob = true
          #        process_subrecord('blob', 'upload')
          process_subrecord("blob", "view")
        elsif @name.empty?
          profile = @form.rectype.profile.name
          rectype = @form.rectype.name
          CCU.log.warn("FORM STRUCTURE: EMPTY HASH: #{profile} - #{rectype} - #{@form.name} contains empty hash under #{@parent.ui_path}")
        elsif @name == "relation-list-item"
          # skip for now
        else
          @form.fields << CCU::Forms::Field.new(self)
        end
      end

      private

      def is_measurement?
        return true if @name == "measuredPartGroupList"
        return true if @parent && @parent.is_measurement
        false
      end

      def is_address?
        return true if @name == "addrGroupList"
        return true if @parent && @parent.is_address
        false
      end

      def process_subrecord(subrec, formname)
        return if @ns == "ns2:acquisitions_omca" # this is a plain field, not a call to contacts subrecord

        @hash = @form.rectype.profile.config["recordTypes"][subrec]["forms"][formname]["template"]["props"]["children"]["props"]
        @is_panel = true
        @is_ext = true
        @panel = @form.rectype.profile.config.dig("recordTypes", subrec,
          "messages", "panel", "info", "id")
        @ns = @form.rectype.profile.config["recordTypes"][subrec]["fields"]["document"]["[config]"]["view"]["props"]["defaultChildSubpath"]
        @ui_path = build_ui_path

        if formname == "upload"
          new(@form, @hash, self)
        else
          CCU::Forms::Children.new(@form, self, @hash["children"])
        end
      end

      def get_panel_id
        if @is_panel
          "panel.#{@form.rectype.name}.#{@name}"
        elsif @parent
          @parent.panel
        else
          ""
        end
      end

      def get_name
        @name = if @hash.dig("name")
          @hash["name"]
        else
          ""
        end
      end

      def get_ns
        ns = if @parent
          @parent.ns
        else
          @form.rectype.ns
        end

        @hash.dig("subpath") ? @hash["subpath"] : ns
        #      ns = "ext.#{@name}" if @is_ext
      end

      def get_ns_for_id
        ns = @parent.ns_for_id if @parent && @parent.ns_for_id.start_with?("ext.")
        ns = "ext.dimension" if is_measurement?
        ns = "ext.address" if is_address? && @is_contact == false
        ns = "ext.accessionattributes" if @ns == "ns2:collectionobjects_accessionattributes"
        ns = "ext.accessionuse" if @ns == "ns2:collectionobjects_accessionuse"
        ns = "ext.fineart" if @ns == "ns2:collectionobjects_fineart"
        ns = "ext.commission" if @ns == "ns2:acquisitions_commission"
        if @ns == "ns2:collectionobjects_variablemedia"
          @name.start_with?("contentWork") ? ns = "ext.contentWorks" : ns = "ext.technicalSpecs"
        end
        if @ns == "ns2:conditionchecks_variablemedia"
          ns = "ext.technicalChanges"
        end
        if @ns == "ns2:persons_publicart" || @ns == "ns2:organizations_publicart"
          ns = "ext.socialMedia" if @name.start_with?("socialMedia")
        end
        ns = "ext.locality" if @name.start_with?("localityGroup")
        ns = @ns if ns.nil?
        ns
      end

      def build_ui_path
        return [] if @name == "document"
        return [] if @is_panel && !@parent
        path = @parent ? @parent.ui_path.clone : []

        if is_input_table
          path << @form.rectype.input_tables[@name]
        elsif is_panel
          path << @panel
        elsif @hash.dig("children") && !@name.empty?
          path << "#{@ns.sub("ns2:", "")}.#{@name}"
        end
        path
      end

      def is_input_table
        true if @form.rectype.input_tables.keys.include?(@name) && @hash["children"]
      end
    end
  end
end
