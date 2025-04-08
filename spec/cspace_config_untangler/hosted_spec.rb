# frozen_string_literal: true

require "spec_helper"

RSpec.describe CCU::Hosted, :aggregate_failures do
  describe ".site_url" do
    let (:result) { CCU::Hosted.site_url(base) }

    context "when staging" do
      let(:base) { "abcstaging" }

      it "returns as expected" do
        expect(result).to eq("https://abc.staging.collectionspace.org")
      end
    end

    context "when prod" do
      let(:base) { "abc" }

      it "returns as expected" do
        expect(result).to eq("https://abc.collectionspace.org")
      end
    end
  end
end
