# frozen_string_literal: true

require_relative "children"
require_relative "field"

module CspaceConfigUntangler
  module Forms
    class IterativeFieldExtractor
      def initialize(form, config, parent = nil)
        @form = form
        @config = config
        @parent = parent
        @rectype = form.rectype
        @profile = rectype.profile
        @props = CCU::Forms::Props.new(form, config, parent)

        # @ns = get_ns
        # @ns_for_id = get_ns_for_id

        # if @ns == "ns2:collectionspace_core"
        #   # skip
        # elsif config.dig("children")
        #   # this catches a form field whose child field is not defined as a field
        #   if @ns == "ns2:works_common" && @name == "workDateGroup"
        #     @form.fields << CCU::Forms::Field.new(self)
        #   else
        #     CCU::Forms::Children.new(@form, self, config["children"])
        #   end
        # elsif @name == "contact" && profile.extensions.include?(@name)
        #   @is_contact = true
        #   process_subrecord("contact", "default")
        # elsif is_blob?
        #   process_subrecord("blob", "view")
        # elsif @name.empty?
        #   profile = profile.name
        #   rectype = rectype.name
        #   CCU.log.warn("FORM STRUCTURE: EMPTY HASH: #{profile} - #{rectype} - #{@form.name} contains empty hash under #{@parent.ui_path}")
        # elsif @name == "relation-list-item"
        #   # skip for now
        # else
        #   @form.fields << CCU::Forms::Field.new(self)
        # end
      end

      def call
        return if props.core?

        if props.bad_work_date?
          form.add_field(CCU::Forms::Field.new(props))
        elsif props.children?
          normalized_children(props.config["children"]).each do |child|
            log_nonstandard_child_keys(child)
            reiterate(child)
          end
        end
      end

      private

      attr_reader :form, :config, :parent,
        :rectype, :profile, :props

      # children are represented as an array of hashes
      # Only one child in the UI config is represented as a hash, while multiple
      # This method converts a single child into an array containing one hash
      def normalized_children(data)
        case data.class.name
        when "Array"
          data
        when "Hash"
          [data]
        end
      end

      # Form children have keys: key, ref, props, and _owner. I'm
      # proceeding based on the assumption that I only care about
      # props because the others are always nil. This method logs any
      # non-nil values for key, ref, or _owner so I can inspect
      def log_nonstandard_child_keys(child)
        %w[key ref _owner].each { |key| check_key(child, key) }
      end

      def check_key(hash, key)
        formatted_key = "#{props.warning_id} #{key}"
        if hash.has_key?(key)
          return if hash[key].nil?

          CCU.log.warn("FORM STRUCTURE: NON-NIL HASH KEY: "\
                       "#{formatted_key} has value: "\
                       "#{hash[key]}")
        else
          CCU.log.warn("FORM STRUCTURE: MISSING HASH KEY: "\
                       "#{formatted_key}")
        end
      end

      def reiterate(hash)
        self.class.new(form, hash, props).call
      end

      # def process_subrecord(subrec, formname)
      #   return if @ns == "ns2:acquisitions_omca" # this is a plain field, not a call to contacts subrecord

      #   @config = profile.config["recordTypes"][subrec]["forms"][formname]["template"]["props"]["children"]["props"]
      #   @is_panel = true
      #   @is_ext = true
      #   @panel = profile.config.dig("recordTypes", subrec,
      #     "messages", "panel", "info", "id")
      #   @ns = profile.config["recordTypes"][subrec]["fields"]["document"]["[config]"]["view"]["props"]["defaultChildSubpath"]
      #   @ui_path = build_ui_path

      #   if formname == "upload"
      #     new(@form, config, self)
      #   else
      #     CCU::Forms::Children.new(@form, self, config["children"])
      #   end
      # end

      # def get_ns_for_id
      #   ns = "ext.dimension" if is_measurement?
      #   ns = "ext.address" if is_address? && @is_contact == false
      #   ns = "ext.accessionattributes" if @ns == "ns2:collectionobjects_accessionattributes"
      #   ns = "ext.accessionuse" if @ns == "ns2:collectionobjects_accessionuse"
      #   ns = "ext.fineart" if @ns == "ns2:collectionobjects_fineart"
      #   ns = "ext.commission" if @ns == "ns2:acquisitions_commission"
      #   if @ns == "ns2:collectionobjects_variablemedia"
      #     @name.start_with?("contentWork") ? ns = "ext.contentWorks" : ns = "ext.technicalSpecs"
      #   end
      #   if @ns == "ns2:conditionchecks_variablemedia"
      #     ns = "ext.technicalChanges"
      #   end
      #   if @ns == "ns2:persons_publicart" || @ns == "ns2:organizations_publicart"
      #     ns = "ext.socialMedia" if @name.start_with?("socialMedia")
      #   end
      #   ns = "ext.locality" if @name.start_with?("localityGroup")
      #   ns = @ns if ns.nil?
      #   ns
      # end

      # def build_ui_path
      #   return [] if @name == "document"
      #   return [] if @is_panel && !@parent
      #   path = @parent ? @parent.ui_path.clone : []

      #   if is_input_table
      #     path << rectype.input_tables[@name]
      #   elsif is_panel
      #     path << @panel
      #   elsif config.dig("children") && !@name.empty?
      #     path << "#{@ns.sub("ns2:", "")}.#{@name}"
      #   end
      #   path
      # end

      # def is_input_table
      #   true if rectype.input_tables.key?(@name) && config["children"]
      # end
    end
  end
end
