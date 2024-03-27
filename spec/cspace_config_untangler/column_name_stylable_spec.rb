# frozen_string_literal: true

require "spec_helper"

RSpec.describe CCU::ColumnNameStylable do
  class ColStyleClass
    include CCU::ColumnNameStylable
  end

  describe "#column_name_style" do
    let(:result) {
      ColStyleClass.new.column_name_style(profile_name, profile_version)
    }

    context "when core 6.1" do
      let(:profile_name) { "core" }
      let(:profile_version) { "6-1-0" }
      it "returns fancy" do
        expect(result).to eq(:fancy)
      end
    end

    context "when core 7.0" do
      let(:profile_name) { "core" }
      let(:profile_version) { "7-0-0" }
      it "returns consistent" do
        expect(result).to eq(:consistent)
      end
    end

    context "when core 9.0" do
      let(:profile_name) { "core" }
      let(:profile_version) { "9-0-0-rc3" }
      it "returns fully consistent" do
        expect(result).to eq(:fully_consistent)
      end
    end

    context "when publicart 2.1.1" do
      let(:profile_name) { "publicart" }
      let(:profile_version) { "2-1-1" }
      it "returns consistent" do
        expect(result).to eq(:consistent)
      end
    end

    context "when publicart 6.0.0" do
      let(:profile_name) { "publicart" }
      let(:profile_version) { "6-0-0-rc2" }
      it "returns fully consistent" do
        expect(result).to eq(:fully_consistent)
      end
    end

    context "with unconfigured profile" do
      let(:profile_name) { "noprofile" }
      let(:profile_version) { "1-1-1" }
      it "returns fully consistent" do
        expect(result).to eq(:fully_consistent)
      end
    end
  end
end
