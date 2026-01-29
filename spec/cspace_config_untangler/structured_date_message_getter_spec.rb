# frozen_string_literal: true

require "spec_helper"

RSpec.describe CCU::StructuredDateMessageGetter, :aggregate_failures do
  subject(:getter) { described_class.new(config) }

  let(:config) do
    path = File.join(fixtures, "config_snippets",
      "structured_date_field_defs.json")
    JSON.parse(File.read(path))
  end

  describe "#call" do
    let(:result) { getter.call }

    it "returns as expected" do
      expect(result).to be_a(CCU::Messages)
      expect(result.size).to eq(getter.send(:fields).length)
    end
  end
end
