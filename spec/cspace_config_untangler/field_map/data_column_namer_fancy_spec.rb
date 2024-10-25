# frozen_string_literal: true

require "spec_helper"

RSpec.describe CCU::FieldMap::DataColumnNamerFancy do
  let(:generator) do
    Helpers::SetupGenerator.new(profile: "core", rectypes: ["collectionobject"],
      release: "6_1")
  end
  let(:profile) { generator.profile }

  let(:fieldname) { "name" }
  let(:xform_sources) do
    sources.map do |source|
      CCU::ValueSources::Authority.new(source, profile)
    end
  end
  let(:result) do
    DataColumnNamerFancy.new(fieldname: fieldname,
      sources: xform_sources).result.values
  end

  context "when source is authority" do
    context "and two authorities may be used" do
      context "and both are concept authorities" do
        let(:sources) { ["concept/one", "concept/two"] }
        it "names columns using authority subtypes" do
          expect(result).to eq(%w[nameOne nameTwo])
        end
      end

      context "and one is person and one is organization" do
        let(:sources) { ["person/local", "organization/local"] }
        it "names columns using authority types" do
          expect(result).to eq(%w[namePerson nameOrganization])
        end
      end
    end

    context "and person/ulan, person/local, org/ulan, and org/local may "\
      "be used" do
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
      it "names columns using authority types and subtypes for person, "\
        "type only for org" do
        expect(result).to eq(%w[namePersonLocal nameOrganization
          namePersonUlan])
      end
    end
  end
end
