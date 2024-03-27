# frozen_string_literal: true

require "spec_helper"

RSpec.describe CCU::Fields::Def::Namespace do
  let(:ns) { CCU::Fields::Def::Namespace.new(str) }
  let(:str) { "ns2:collectionobjects_common" }

  describe "#literal" do
    let(:result) { ns.literal }
    it "returns literal namespace from rectype/fields/document config" do
      expect(result).to eq(str)
    end
  end

  describe "#for_id" do
    let(:result) { ns.for_id }

    context "when same as literal namespace" do
      it "returns literal namespace" do
        expect(result).to eq(str)
      end
    end

    context "when adjusted namespace" do
      let(:str) { "ns2:propagations_common" }
      it "returns adjusted namespace" do
        expect(result).to eq("ns2:propagation_common")
      end
    end
  end
end
