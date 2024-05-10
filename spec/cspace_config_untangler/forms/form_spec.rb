# frozen_string_literal: true

require "spec_helper"

RSpec.describe CCU::Forms::Form do
  let(:release) { "8_0" }
  let(:profilename) { "anthro" }
  let(:rectypes) { ["collectionobject"] }
  let(:generator) do
    Helpers::SetupGenerator.new(profile: profilename, rectypes: rectypes,
      release: release)
  end
  let(:form) { generator.form(templatename) }

  describe "#disabled?" do
    let(:result) { form.disabled? }

    context "when enabled" do
      let(:templatename) { "inventory" }

      it "returns false" do
        expect(result).to be false
      end
    end

    context "when disabled" do
      let(:templatename) { "timebased" }

      it "returns true" do
        expect(result).to be true
      end
    end
  end

  describe "#enabled?" do
    let(:result) { form.enabled? }

    context "when disabled" do
      let(:templatename) { "timebased" }

      it "returns false" do
        expect(result).to be false
      end
    end

    context "when enabled" do
      let(:templatename) { "inventory" }

      it "returns true" do
        expect(result).to be true
      end
    end
  end

  describe "#id" do
    let(:templatename) { "inventory" }
    let(:result) { form.id }

    it "returns id" do
      expect(result).to eq("anthro_8-0-0 collectionobject inventory")
    end
  end
end
