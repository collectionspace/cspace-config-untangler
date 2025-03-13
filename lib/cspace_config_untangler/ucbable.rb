# frozen_string_literal: true

require_relative "namespaceable"

# Mix in module with logic for dealing with non-standard patterns in UCB
#   profiles
module CspaceConfigUntangler
  module Ucbable
    include Namespaceable

    # Reported in DRYD-1709
    # @param config [Hash] form props object
    def ucb_namespace_wrapper_props?(config)
      return unless respond_to?(:profile) &&
        profile.name.match?(/^(ucbg|ucjeps)/)
      return unless respond_to?(:props) &&
        props.profile.name.match?(/^(ucbg|ucjeps)/)

      config.key?("name") &&
        namespace?(config["name"]) &&
        config.key?("subpath") &&
        config["subpath"].empty? &&
        config.key?("children")
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
      # Reported in DRYD-1724
      true if profile.name.start_with?("ucjeps") &&
        name == "assocPeople" &&
        %w[chronology person place].include?(rectype.name)
    end

    def ucb_second_adv_search_ns?(rectype)
      true if rectype.profile.name.start_with?("ucbg") &&
        rectype.name == "loanout"
      true if rectype.profile.name.start_with?("ucjeps") &&
        rectype.name == "loanin"
    end

    def ucb_third_adv_search_ns?(rectype)
      rectype.profile.name.start_with?("ucbg") && rectype.name == "media"
    end
  end
end
