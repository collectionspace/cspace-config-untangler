require "spec_helper"

RSpec.describe CCU::Release do
  subject(:release) { described_class.new(version) }

  context "when valid version given" do
    let(:version) { "7_2" }

    it "initializes with version" do
      expect(release.version).to eq(version)
    end
  end

  context "when no version given" do
    let(:version) { nil }

    it "initializes with latest known version" do
      expect(release.version).to eq(CCU.releases.last)
    end
  end

  context "when invalid version given" do
    let(:version) { "7_3" }

    it "raises ArgumentError" do
      expect { release }.to raise_error(ArgumentError)
    end
  end

  describe "#lt" do
    let(:result) { release.lt(other_version) }
    let(:version) { "7_2" }

    context "with later version" do
      let(:other_version) { "8_0" }

      it "returns true" do
        expect(result).to be true
      end
    end

    context "with self" do
      let(:other_version) { "7_2" }

      it "returns false" do
        expect(result).to be false
      end
    end

    context "with earlier version" do
      let(:other_version) { "6_1" }

      it "returns false" do
        expect(result).to be false
      end
    end
  end

  describe "#lte" do
    let(:result) { release.lte(other_version) }
    let(:version) { "7_2" }

    context "with later version" do
      let(:other_version) { "8_0" }

      it "returns true" do
        expect(result).to be true
      end
    end

    context "with self" do
      let(:other_version) { "7_2" }

      it "returns true" do
        expect(result).to be true
      end
    end

    context "with earlier version" do
      let(:other_version) { "6_1" }

      it "returns false" do
        expect(result).to be false
      end
    end
  end

  describe "#gt" do
    let(:result) { release.gt(other_version) }
    let(:version) { "7_2" }

    context "with later version" do
      let(:other_version) { "8_0" }

      it "returns false" do
        expect(result).to be false
      end
    end

    context "with self" do
      let(:other_version) { "7_2" }

      it "returns false" do
        expect(result).to be false
      end
    end

    context "with earlier version" do
      let(:other_version) { "6_1" }

      it "returns true" do
        expect(result).to be true
      end
    end
  end

  describe "#gte" do
    let(:result) { release.gte(other_version) }
    let(:version) { "7_2" }

    context "with later version" do
      let(:other_version) { "8_0" }

      it "returns false" do
        expect(result).to be false
      end
    end

    context "with self" do
      let(:other_version) { "7_2" }

      it "returns true" do
        expect(result).to be true
      end
    end

    context "with earlier version" do
      let(:other_version) { "6_1" }

      it "returns true" do
        expect(result).to be true
      end
    end
  end

  describe "#previous" do
    let(:result) { release.previous }

    context "when there is a previous version" do
      let(:version) { "8_0" }

      it "returns previous version" do
        expect(result).to eq("7_2")
      end
    end

    context "when there is no previous version" do
      let(:version) { "5_2" }

      it "returns nil" do
        expect(result).to be_nil
      end
    end
  end

  describe "#next" do
    let(:result) { release.next }

    context "when there is a next version" do
      let(:version) { "7_2" }

      it "returns next version" do
        expect(result).to eq("8_0")
      end
    end

    context "when there is no next version" do
      let(:version) { CCU.releases.last }

      it "returns nil" do
        expect(result).to be_nil
      end
    end
  end
end
