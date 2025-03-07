# frozen_string_literal: true

require_relative "field"
require_relative "props"
require_relative "subrecord"

module CspaceConfigUntangler
  module Forms
    class IterativeFieldExtractor
      def initialize(form, config)
        @form = form
        @config = config
        @parent = parent
        @rectype = form.rectype
        @profile = rectype.profile
        @validator = CCU::Forms::PropsValidator.new
        @initialprops = CCU::Forms::Props.new(form, validator, config)
        @allprops = []
      end

      def call(props = initialprops)
        allprops << props
        return if props.skippable?
        return unless props.valid?

        case props.treatment
        when :field
          add_form_field(props)
        when :subrecord
          process_subrecord(props)
        when :props
          reiterate(props.config["props"], props)
        when :content_free_parent
          process_children(props, :self)
        when :content_bearing_parent
          process_children(props, :self)
        end

        form.fields
      end

      def to_s
        "<##{self.class}:#{object_id.to_s(8)}\n"\
          "  profile-rectype-form: #{profile.name}/#{rectype.name}/"\
          "#{form.name}>"
      end
      alias_method :inspect, :to_s

      # private

      attr_reader :form, :config, :parent, :rectype, :profile,
        :validator, :initialprops, :allprops

      def add_form_field(props)
        form.add_field(CCU::Forms::Field.new(props))
      end

      def process_children(props, parentmode)
        parent = (parentmode == :self) ? props : props.parent
        normalized_children(props).each do |child|
          reiterate(child, parent)
        end
      end

      def process_subrecord(props)
        subrec = CCU::Forms::Subrecord.new(props.name, form, validator, props)
        process_children(subrec, :self)
      end

      def reiterate(hash, parent)
        newprops = CCU::Forms::Props.new(form, validator, hash, parent)
        call(newprops)
      end

      # children are represented as an array of hashes
      # Only one child in the UI config is represented as a hash, while multiple
      # This method converts a single child into an array containing one hash
      def normalized_children(props) = [props.config["children"]].flatten
    end
  end
end
