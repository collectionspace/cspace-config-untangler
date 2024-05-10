# frozen_string_literal: true

require "spec_helper"

RSpec.describe CCU::Fields::Def::Config do
  let(:generator) do
    Helpers::SetupGenerator.new(profile: "core", rectypes: ["collectionobject"])
  end
  let(:ns) { "ns2:collectionobjects_common" }
  let(:config) { generator.field_def_config(ns) }

  describe "#namespace" do
    let(:result) { config.namespace }

    it "returns a Namespace object" do
      expect(result).to be_a(CCU::Fields::Def::Namespace)
    end
  end

  describe "#hash" do
    let(:result) { config.hash }

    it "returns a Hash" do
      expect(result).to be_a(Hash)
    end
  end

  describe "#update_field_hash" do
    it "updates field hash and does not mess with original config data" do
      old_hash = generator.field_def_hash[ns]
      new_hash = {foo: "bar"}
      config.update_field_hash(new_hash)
      expect(config.hash).to eq(new_hash)
      expect(old_hash.keys.any?("objectNumber")).to be true
    end
  end
end
