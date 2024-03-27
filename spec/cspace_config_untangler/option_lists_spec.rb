# frozen_string_literal: true

require "spec_helper"

RSpec.describe CCU::OptionLists do
  let(:config) do
    JSON.parse(File.read(File.join(fixtures, "config_snippets",
      "option_list.json")))
  end
  let(:lists) { CCU::OptionLists.new(config) }
  let(:name) { "inscriptionTypes" }

  describe "#names" do
    let(:result) { lists.names }
    it "returns Array of all profile option list names as Strings" do
      expect(result).to be_a(Array)
      expect(result.length).to eq(91)
      expect(result.any?(name)).to be true
    end
  end

  describe "#get_option_list" do
    let(:result) { lists.get_option_list(name) }
    it "returns a CCU::ValueSources::OptionList" do
      expect(result).to be_a(CCU::ValueSources::OptionList)
    end
  end
end
