# frozen_string_literal: true

require "spec_helper"

RSpec.describe CCU::FieldMap::FieldMapping do
  let(:generator) do
    Helpers::SetupGenerator.new(profile: profilename, rectypes: rectypes,
      release: release)
  end
  let(:profilename) { "core" }
  let(:rectypes) { ["collectionobject", "concept", "movement"] }
  let(:release) { "6_0" }
  let(:profile) { generator.profile }
  let(:field) { generator.field(fieldrec, fieldname) }
  let(:mapper) { FieldMapper.new(field: field) }
  let(:mappings) { mapper.mappings }

  context "core profile" do
    context "contentConcept" do
      let(:fieldrec) { "collectionobject" }
      let(:fieldname) { "contentConcept" }
      it "mappings have source_type = authority" do
        result = mappings.map { |m| m.source_type }
        expect(result).to eq(%w[authority authority refname])
      end
      it "mappings datacolumns = contentConceptConceptAssociated contentConceptConceptMaterial" do
        result = mappings.map { |m| m.datacolumn }.sort
        expect(result).to eq(%w[contentConceptConceptAssociated
          contentConceptConceptMaterial contentConceptRefname])
      end

      describe ".to_h" do
        it "gets all attributes" do
          hash = mappings[0].to_h
          expect(hash.key?(:datacolumn)).to be true
        end
      end
    end

    context "currentLocation" do
      let(:fieldrec) { "movement" }
      let(:fieldname) { "currentLocation" }
      it "mappings have source_type = authority" do
        result = mappings.map { |m| m.source_type }
        expect(result).to eq(%w[authority authority authority refname])
      end
      it "mappings datacolumns = currentLocationLocationLocal currentLocationLocationOffsite currentLocationOrganizationLocal currentLocationRefname" do
        result = mappings.map { |m| m.datacolumn }.sort
        expect(result).to eq(%w[currentLocationLocationLocal currentLocationLocationOffsite currentLocationOrganizationLocal
          currentLocationRefname])
      end

      describe ".to_h" do
        it "gets all attributes" do
          hash = mappings[0].to_h
          expect(hash.key?(:datacolumn)).to be true
        end
      end
    end
  end
end
