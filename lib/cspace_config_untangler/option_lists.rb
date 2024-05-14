# frozen_string_literal: true

module CspaceConfigUntangler
  # aggregate class to build and store option lists belonging to a profile
  class OptionLists
    attr_reader :names
    def initialize(option_list_config)
      config = option_list_config
      @names = config.keys
      @all = {}
      config.each do |name, list_config|
        @all[name] = CCU::ValueSources::OptionList.new(name, list_config)
      end
    end

    def get_option_list(name)
      @all[name]
    end
  end
end
