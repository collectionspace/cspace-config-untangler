# frozen_string_literal: true

require "spec_helper"

RSpec.describe CCU::Profile do
  let(:release) { "8_2" }
  let(:profilename) { "botgarden" }
  let(:rectypes) { %w[loanout movement] }
  let(:generator) do
    Helpers::SetupGenerator.new(profile: profilename, rectypes: rectypes,
      release: release)
  end

  describe "message overrides" do
    # let(:field) { generator.field("collectionobject", "objectHistoryNote") }

    it "return as expected", :aggregate_failures do
      loan = generator.rectype("loanout")
      expect(loan.label).to eq("Voucher")

      mov = generator.rectype("movement")
      expect(mov.label).to eq("Current Location")
    end
  end
end
