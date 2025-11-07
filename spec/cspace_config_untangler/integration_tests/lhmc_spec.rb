# frozen_string_literal: true

require "spec_helper"

RSpec.describe CCU::Profile do
  let(:release) { "8_2" }
  let(:profilename) { "lhmc" }
  let(:rectypes) { ["collectionobject"] }
  let(:generator) do
    Helpers::SetupGenerator.new(profile: profilename, rectypes: rectypes,
      release: release)
  end

  describe "message overrides" do
    let(:field) { generator.field("collectionobject", "objectHistoryNote") }

    it "returns false" do
      expect(field.label).to eq("Provenance")
    end
  end
end
