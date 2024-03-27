require "spec_helper"

RSpec.describe CCU::FieldMap::DataColumnNamerConsistent do
  let(:generator) {
    Helpers::SetupGenerator.new(profile: "core", rectypes: ["collectionobject"],
      release: "7_0")
  }
  let(:profile) { generator.profile }

  let(:fieldname) { "name" }
  let(:xform_sources) {
    sources.map { |source|
      CCU::ValueSources::Authority.new(source, profile)
    }
  }
  let(:result) {
    DataColumnNamerConsistent.new(fieldname: fieldname,
      sources: xform_sources).result.values
  }

  context "when source is authority" do
    context "and two authorities may be used" do
      context "and both are concept authorities" do
        let(:sources) { ["concept/one", "concept/two"] }
        it "names columns using authority subtypes" do
          expect(result).to eq(%w[nameConceptOne nameConceptTwo])
        end
      end

      context "and one is person and one is organization" do
        let(:sources) { ["person/local", "organization/local"] }
        it "names columns using authority types" do
          expect(result).to eq(%w[namePersonLocal nameOrganizationLocal])
        end
      end
    end

    context "and person/ulan, person/local, org/ulan, and org/local may be used" do
      let(:sources) do
        ["person/local", "organization/local",
          "person/ulan", "organization/ulan"]
      end
      it "names all columns using authority types and subtypes" do
        expect(result).to eq(%w[namePersonLocal nameOrganizationLocal
          namePersonUlan nameOrganizationUlan])
      end
    end

    context "and person/ulan, person/local, and org/local may be used" do
      let(:sources) { ["person/local", "organization/local", "person/ulan"] }
      it "names columns using authority types and subtypes for person, type only for org" do
        expect(result).to eq(%w[namePersonLocal nameOrganizationLocal
          namePersonUlan])
      end
    end
  end
end
