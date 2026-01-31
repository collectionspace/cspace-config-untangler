# frozen_string_literal: true

require "spec_helper"

RSpec.describe CCU::Fields::Field do
  subject(:field) { generator.field(rectypes.first, fieldname) }

  let(:generator) do
    Helpers::SetupGenerator.new(profile: profilename, rectypes: rectypes,
      release: release)
  end

  context "with bonsai conservation conservator" do
    let(:release) { "8_2" }
    let(:profilename) { "bonsai" }
    let(:rectypes) { ["conservation"] }
    let(:fieldname) { "conservator" }

    it "returns profile override message" do
      expect(field.label).to eq("Treatment performed by")
    end
  end

  context "with bonsai conservation sampleReturned" do
    let(:release) { "8_0" } # bug fixed in 8.1.1
    let(:profilename) { "bonsai" }
    let(:rectypes) { ["conservation"] }
    let(:fieldname) { "sampleReturned" }

    it "messages account for config typo" do
      orig_id = "field.conservation_common.sampleReturned.nadme"
      ok_id = "field.conservation_common.sampleReturned.name"
      expect(
        field.messages.by_id(orig_id)&.message
      ).to eq("Sample returned")
      expect(
        field.messages.by_id(ok_id)&.message
      ).to eq("Sample returned")
    end
  end
end
