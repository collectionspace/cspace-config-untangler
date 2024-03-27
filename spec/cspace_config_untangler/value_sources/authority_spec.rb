# frozen_string_literal: true

require "spec_helper"

RSpec.describe CCU::ValueSources::Authority do
  let(:generator) {
    Helpers::SetupGenerator.new(profile: profilename, rectypes: rectypes,
      release: release)
  }
  let(:profilename) { "core" }
  let(:rectypes) { ["collectionobject"] }
  let(:release) { "6_0" }
  let(:profile) { generator.profile }
  let(:str) { "concept/associated" }
  let(:authority) { CCU::ValueSources::Authority.new(str, profile) }

  describe "#name" do
    let(:result) { authority.name }
    it "returns name" do
      expect(result).to eq(str)
    end
  end

  describe "#type" do
    let(:result) { authority.type }
    it "returns type" do
      expect(result).to eq("concept")
    end
  end

  describe "#subtype" do
    let(:result) { authority.subtype }
    it "returns subtype" do
      expect(result).to eq("associated")
    end
  end

  describe "#configured?" do
    let(:result) { authority.configured? }
    context "when configured" do
      it "returns true" do
        expect(result).to be true
      end
    end

    context "when configured" do
      let(:str) { "concept/material_shared" }
      it "returns false" do
        expect(result).to be false
      end
    end
  end

  describe "#service_paths" do
    let(:result) { authority.service_paths }
    context "when concept/associated" do
      it "returns service paths" do
        expect(result).to eq(["conceptauthorities", "concept"])
      end
    end

    context "when concept/material" do
      let(:str) { "concept/material" }
      it "returns service paths" do
        expect(result).to eq(["conceptauthorities", "material_ca"])
      end
    end

    context "when person/ulan" do
      let(:str) { "person/ulan" }
      it "returns service paths" do
        expect(result).to eq(["personauthorities", "ulan_pa"])
      end
    end
  end
end
