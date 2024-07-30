# frozen_string_literal: true

module CspaceConfigUntangler
  class MessageId
    attr_reader :full_id, :element_type

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
      inputTable: 3,
      panel: 3,
      record: 2,
      vocab: 3
    }.freeze

    # Element types whose id patterns do not include a message type.
    #   See the doc/ui_config_notes.adoc page for more info/examples
    NO_MESSAGE_TYPES = %i[about inputTable panel].freeze

    # @param id [String]
    def initialize(id)
      @full_id = id
      @working = if id.start_with?("field.") && id["ext."]
        id.sub("ext.", "ext%%DOT%%")
      else
        id
      end
      @parts = working.split(".")
      @element_type = parts.first.to_sym
    end

    # @return [String] the ID with message type segment removed, if present
    def base_id = @base ||= set_base_id

    # @return [Symbol] defaulting to :label if no type specified in id
    def message_type = @message_type ||= set_message_type

    # @return [String]
    def element_name = @element_name ||= set_element_name

    private

    attr_reader :parts, :working

    def set_base_id
      return column_base_id if element_type == :column

      parts.first(BASE_ID_SEGMENTS[element_type])
        .join(".")
        .sub("ext%%DOT%%", "ext.")
    end

    def column_base_id = [parts[0], parts[1], parts[3]].join(".")

    def set_message_type
      return :label if NO_MESSAGE_TYPES.include?(element_type)
      return parts[2].to_sym if element_type == :column

      parts.last.to_sym
    end

    def set_element_name
      case element_type
      when :field
        parts[2]
      when :record
        parts[1]
      else
        parts.last
      end
    end
  end
end
