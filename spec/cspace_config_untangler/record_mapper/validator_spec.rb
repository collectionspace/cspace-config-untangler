# frozen_string_literal: true

require "spec_helper"

RSpec.describe CCU::RecordMapper::Validator do
  subject(:val) { described_class.new(path, style) }
  let(:basepath) { File.join(fixtures, "files", "9_0", "mappers") }
  let(:path) { File.join(basepath, file) }

  describe "#validate" do
    before(:each) { val.validate }

    let(:result) { val.valid }

    context "when style == :csvimporter" do
      let(:style) { :csvimporter }

      context "when mapper is valid" do
        let(:file) { "anthro_acq_ci_v.json" }

        it "returns true" do
          expect(result).to be true
        end
      end

      context "when mapper is invalid" do
        let(:file) { "anthro_acq_ci_iv.json" }

        it "returns false" do
          expect(result).to be false
        end

        it "has expected error message" do
          expect(val.errors).to include("Profile lacks config/version")
        end
      end
    end

    context "when style == :datatoolkit" do
      let(:style) { :datatoolkit }

      context "when mapper is valid" do
        let(:file) { "anthro_acq_dt_v.json" }

        it "returns true" do
          expect(result).to be true
        end
      end

      context "when mapper is invalid" do
        let(:file) { "anthro_acq_dt_iv.json" }

        it "returns false" do
          expect(result).to be false
        end

        it "has expected error message" do
          expect(val.errors).to include("No dataConfigType specified")
        end
      end
    end
  end
end
