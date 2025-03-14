# frozen_string_literal: true

require_relative "namespaceable"

# Mix in module with logic for dealing with non-standard patterns in UCB
#   profiles
module CspaceConfigUntangler
  module Ucbable
    include Namespaceable

    def ucb_skippable_form_field?(props)
      props.profile.name.start_with?("ucjeps") &&
        props.rectype.name == "collectionobject" &&
        props.name == "numberOfObjects"
    end

    def ucb_known_keysig?(props)
      ucb_namespace_wrapper_props?(props) ||
        ucb_children_labelmessage_name?(props) ||
        ucb_children_labelmessage_name_subpath?(props)
    end

    # Reported in DRYD-1709
    # @param props [CCU::Form::Props]
    def ucb_namespace_wrapper_props?(props)
      return unless props.profile.name.match?(/^(ucbg|ucjeps)/)

      props.config.keys.sort == %w[children name subpath tabular] &&
        props.namespace?(props.config["name"]) &&
        props.config["subpath"].empty?
    end

    # Reported in DRYD-1726
    # @param props [CCU::Form::Props]
    def ucb_children_labelmessage_name?(props)
      return unless props.profile.name.match?(/^(ucjeps)/)

      props.config.keys.sort == %w[children labelMessage name]
    end

    # Reported in DRYD-1729
    # @param props [CCU::Form::Props]
    def ucb_children_labelmessage_name_subpath?(props)
      return unless props.profile.name.match?(/^(ucjeps)/)

      props.config.keys.sort == %w[children labelMessage name subpath]
    end

    # Reported in DRYD-1708
    # @param fieldconfig [Hash] field definition object
    def vestigial_annotation_author?(fieldconfig)
      config.ns.literal == "ns2:collectionobjects_naturalhistory" &&
        fieldconfig.keys == ["annotationGroup"]
    end

    # Reported in DRYD-1710, DRYD-1723
    # @param form [CCU::Forms::Form]
    def ucb_wrongly_inherited_form?(form)
      case form.profile.name
      when /^(ucbg|ucjeps)/
        %w[public timebased].include?(form.name)
      else
        false
      end
    end

    def ucb_controlled_by_missing_authority?
      # Reported in DRYD-1724, DRYD-1730
      true if profile.name.match?(/^(ucjeps|pahma)/) &&
        %w[chronology person place].include?(rectype.name) &&
        name == "assocPeople"
    end

    def ucb_second_adv_search_ns?(rectype)
      true if (rectype.profile.name.start_with?("ucbg") &&
        rectype.name == "loanout") ||
        (rectype.profile.name.start_with?("ucjeps") &&
          rectype.name == "loanin")
    end

    def ucb_third_adv_search_ns?(rectype)
      rectype.profile.name.start_with?("ucbg") && rectype.name == "media"
    end
  end
end
