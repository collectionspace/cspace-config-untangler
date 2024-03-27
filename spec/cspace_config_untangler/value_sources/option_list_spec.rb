# frozen_string_literal: true

require "spec_helper"

RSpec.describe CCU::ValueSources::OptionList do
  let(:name) { "loanPurposes" }
  let(:config) do
    JSON.parse(File.read(File.join(fixtures, "config_snippets",
      "option_list.json")))[name]
  end
  let(:list) { CCU::ValueSources::OptionList.new(name, config) }

  describe "#name" do
    let(:result) { list.name }
    it "returns name" do
      expect(result).to eq(name)
    end
  end

  describe "#options" do
    let(:result) { list.options }
    it "returns Array of allowed option term Strings" do
      expect(result).to be_a(Array)
      expect(result.length).to eq(7)
      expect(result.any?("analysis")).to be true
    end
  end
end
