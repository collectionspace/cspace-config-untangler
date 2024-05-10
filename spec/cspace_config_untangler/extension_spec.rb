# frozen_string_literal: true

require "spec_helper"

RSpec.describe CCU::Extension do
  let(:release) { "6_1" }
  let(:rectypes) { ["collectionobject"] }
  let(:generator) do
    Helpers::SetupGenerator.new(profile: profilename, rectypes: rectypes,
      release: release)
  end

  context "when core rectype" do
    let(:profilename) { "core" }

    context "when address extension" do
      let(:ext) { generator.extension("address") }

      it "creates CCU::Extension object" do
        expect(ext).to be_instance_of(CCU::Extension)
      end

      it "determines extension type: generic" do
        expect(ext.type).to eq("generic")
      end
      it "sets empty rectypes array when type: generic" do
        expect(ext.rectypes).to eq([])
      end
    end
  end

  context "when anthro rectype" do
    let(:profilename) { "anthro" }
    let(:rectypes) { ["collectionobject", "claim"] }

    context "when nagpra extension" do
      let(:ext) { generator.extension("nagpra") }

      it "determines extension type: rectype specific" do
        expect(ext.type).to eq("rectype specific")
      end

      it "records affected rectypes when type: rectype specific" do
        expect(ext.rectypes).to eq(%w[claim collectionobject])
      end
    end

    context "when contact subrecord" do
      let(:ext) { generator.extension("contact") }
      it "determines extension type: subrecord" do
        expect(ext.type).to eq("subrecord")
      end
    end
  end
end # RSpec
