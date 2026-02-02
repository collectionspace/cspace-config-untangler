# frozen_string_literal: true

module CspaceConfigUntangler
  class MessageId
    attr_reader :orig_id

    # How many id segments to keep as part of base id for lookup.
    #
    # For elements with different message types defined, overrides
    #  (and possibly other future references) refer to a specific
    #  message type by appending "name" or "fullName" as the last
    #  part of the id value.
    BASE_ID_SEGMENTS = {
      about: 2,
      column: 4,
      field: 3,
      form: 3,
      inputTable: 3,
      panel: 3,
      record: 2,
      vocab: 3
    }.freeze

    # Element types whose id patterns do not include a message type.
    #   See the doc/ui_config_notes.adoc page for more info/examples
    NO_MESSAGE_TYPES = %i[about inputTable panel].freeze

    # A category of CollectionSpace inconsistency
    PANELS_THAT_ARE_INPUT_TABLES = %w[
      panel.collectionobject.flowers
      panel.collectionobject.fruits
      panel.ext.nagpra.nagpraReportFiled
    ]

    # @param id [String]
    def initialize(id)
      @orig_id = id
    end

    # Allows you to group messages by the element they refer to
    # @return [String] the ID with message type segment removed, if present.
    def base_id = @base_id ||= set_base_id

    # @return [String] the ID with message type segment removed, if present.
    def normalized_base_id = @normalized_base_id ||= set_base_id(:normalized_id)

    # @return [Symbol] the kind of element (field, form, etc.) to which the id
    #   applies
    def element_type = @element_type ||= parts(:normalized_id).first.to_sym

    # @return [String] field, form, panel, record type, etc. to which the
    #   id applies
    def element_name = @element_name ||= set_element_name

    # @return [String]
    def normalized_id = @normalized_id ||= prepare_normalized_id

    # @return [Symbol] defaulting to :label if no type specified in id
    def message_type = @message_type ||= set_message_type

    # Is there an exact match between this id's orig_id and the given string?
    # @param otherid [String]
    def match?(otherid) = orig_id == otherid

    # Is there an exact match the given string and this id's orig_id or
    #   normalized_id?
    # @param otherid [String]
    def norm_match?(otherid) = match?(otherid) ||
      otherid == normalized_id.sub("ext%%DOT%%", "ext.")

    # Does this id's base_id match the base id created for the other id?
    # @param otherid [String]
    def base_match?(otherid) = MessageId.new(otherid).base_id == base_id

    # Does this id's base_id match the base id created for the other id?
    # @param otherid [String]
    def norm_base_match?(otherid)
      other = MessageId.new(otherid).base_id
      base_id == other || normalized_base_id == other
    end

    private

    # @return [String]
    def segment_safe_id = @segment_safe_id ||= prepare_segment_safe_id

    # `ext.` replacement is to prevent `ext.{name of extension}` from being
    #   split into 2 segments
    def prepare_segment_safe_id
      return orig_id unless orig_id[".ext."]

      orig_id.sub(".ext.", ".ext%%DOT%%")
    end

    def prepare_normalized_id
      if segment_safe_id.start_with?("panel.") &&
          PANELS_THAT_ARE_INPUT_TABLES.include?(segment_safe_id)
        segment_safe_id.sub("panel.", "inputTable.")
      elsif segment_safe_id.start_with?("field.conservation_livingplant")
        segment_safe_id.sub("field.conservation_livingplant",
          "field.ext%%DOT%%livingplant")
      elsif orig_id == "field.conservation_common.sampleReturned.nadme"
        CCU.upgrade_warner.call(
          target_version: "next release", issue: "DRYD-1271"
        )

        "field.conservation_common.sampleReturned.name"
      elsif orig_id.start_with?("field.uoc_common.hoursSpent")
        CCU.upgrade_warner.call(target_version: "next release",
          issue: "DRYD-1269")

        orig_id.sub("hoursSpent", "useDateHoursSpent")
      elsif orig_id.start_with?(
        "field.collectionobjects_common.compressionstandard"
      )
        CCU.upgrade_warner.call(target_version: "next release",
          issue: "DRYD-1270")

        orig_id.sub("compressionstandard", "compressionStandard")
      else
        segment_safe_id
      end
    end

    # @param [:segment_safe_id, :normalized_id]
    # @return [Array<String>]
    def parts(source = :segment_safe_id)
      send(source).split(".")
        .map { |seg| seg["ext%%DOT%%"] ? seg.sub("ext%%DOT%%", "ext.") : seg }
    end

    def set_base_id(source = :segment_safe_id)
      return column_base_id if element_type == :column

      keep_segments = BASE_ID_SEGMENTS[element_type]
      parts(source).first(keep_segments)
        .join(".")
    end

    def column_base_id = [parts[0], parts[1], parts[3]].join(".")

    def set_message_type
      return :label if NO_MESSAGE_TYPES.include?(element_type)
      return parts(:normalized_id)[2].to_sym if element_type == :column

      parts(:normalized_id).last.to_sym
    end

    def set_element_name
      case element_type
      when :field
        parts[2]
      when :form
        parts[2]
      when :record
        parts[1]
      else
        parts.last
      end
    end
  end
end
