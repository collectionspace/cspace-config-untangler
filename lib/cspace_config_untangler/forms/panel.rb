# frozen_string_literal: true

require_relative "form"

module CspaceConfigUntangler
  class Panel < CCU::Form
    attr_reader :rectype, :name, :fields

    def initialize(rectypeobj, formname)
      @rectype = rectypeobj
      @name = formname
      @config = get_config
      @fields = get_form_fields
    end

    private

    def get_form_fields
      @config.each { |panel| process_panel(panel) }
    end

    def process_panel(panel)
      # As of 2020-04-14, all key, ref, and _owner values at the panel level are nil
      panel = panel["props"]
      panel_name = panel["name"]
      if panel_name == "contact"
        # figure out how to get fields from subrecord treated as extension
      else
        get_panel_children(panel)
      end
    end

    def get_panel_children(panel)
      children = panel["children"]
      puts "#{children.class} -- #{rectype.id} #{panel["name"]}"
    end

    def get_config
      config = @rectype.config["forms"][@name]["template"]["props"]["children"]
      standardize_form_data(config)
    end

    # if there is only one child, it gets created as a hash
    # if there are multiple children, they are an array of hashes
    # turns a single child into an array containing one hash
    def standardize_form_data(data)
      if data.is_a?(Hash)
        [data]
      elsif data.is_a?(Array)
        data
      end
      report_non_nil_keys(data)
      data
    end

    # form children have keys: key, ref, props, and _owner
    # I'm proceeding based on the assumption that I only care about props because
    #  the others are always nil
    # This logs any non-nil values for key, ref, or _owner so I can inspect
    def report_non_nil_and_missing_keys(data)
      data.each do |h|
        %w[key ref _owner].each { |k| check_key(h, k) }
      end
    end

    def check_key(hash, key)
    end
  end # class Form
end # module
