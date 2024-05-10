# frozen_string_literal: true

require "spec_helper"

RSpec.describe CCU::FieldMap::FieldMapper do
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

  context "when no field source" do
    let(:fieldrec) { "collectionobject" }
    let(:fieldname) { "assocActivity" }

    describe "#get_data_columns" do
      it "column is the same as field name" do
        expect(mapper.hash.map do |src, h|
                 h[:column_name]
               end).to eq(["assocActivity"])
      end
    end
    describe "#mappings" do
      it "returns 1 mapping" do
        expect(mapper.mappings.size).to eq(1)
      end
    end
    describe "#source_type" do
      it "returns na" do
        expect(mapper.source_type).to eq("na")
      end
    end
  end

  context "when field source is option list" do
    let(:fieldrec) { "collectionobject" }
    let(:fieldname) { "ageUnit" }

    describe "#get_data_columns" do
      it "column is the same as field name" do
        expect(mapper.hash.map { |src, h| h[:column_name] }).to eq(["ageUnit"])
      end
    end
    describe "#mappings" do
      it "returns 1 mapping" do
        expect(mapper.mappings.size).to eq(1)
      end
    end
    describe "#source_type" do
      it "returns optionlist" do
        expect(mapper.source_type).to eq("optionlist")
      end
    end
  end

  context "when field source is vocabulary" do
    context "we assume only one vocabulary source per field" do
      let(:fieldrec) { "collectionobject" }
      let(:fieldname) { "ageQualifier" }

      describe "#get_data_columns" do
        it "column is the same as field name" do
          expect(mapper.hash.map do |src, h|
                   h[:column_name]
                 end).to eq(["ageQualifier", "ageQualifierRefname"])
        end
      end
      describe "#mappings" do
        it "returns 2 mappings" do
          expect(mapper.mappings.size).to eq(2)
        end
      end
      describe "#get_transforms" do
        it "creates transform hash as expected" do
          rh = mapper.hash.map { |src, h| h[:transforms] }
          expected = [
            {vocabulary: "agequalifier"},
            {}
          ]
          expect(rh).to eq(expected)
        end
      end
      describe "#source_type" do
        it "returns vocabulary" do
          expect(mapper.source_type).to eq("vocabulary")
        end
      end
    end
  end

  context "when field source is authority" do
    context "and two authorities may be used" do
      let(:fieldrec) { "collectionobject" }
      let(:fieldname) { "contentConcept" }

      describe "#get_data_columns" do
        it "merges in column name hash as expected" do
          expect(mapper.hash.map { |src, h| h[:column_name] }).to eq(
            %w[contentConceptConceptAssociated contentConceptConceptMaterial
              contentConceptRefname]
          )
        end
      end
      describe "#mappings" do
        it "returns 3 mappings" do
          expect(mapper.mappings.size).to eq(3)
        end
      end
      describe "#get_transforms" do
        it "creates transform hashes as expected" do
          rh = mapper.hash.map { |src, h| h[:transforms] }
          expected = [
            {authority: %w[conceptauthorities concept]},
            {authority: %w[conceptauthorities material_ca]},
            {}
          ]
          expect(rh).to eq(expected)
        end
      end
      describe "#source_type" do
        it "returns authority" do
          expect(mapper.source_type).to eq("authority")
        end
      end
    end

    context "and one authority may be used, 8.0 or after" do
      let(:release) { "8_0" }
      let(:fieldrec) { "collectionobject" }
      let(:fieldname) { "objectNameControlled" }

      describe "#get_data_columns" do
        it "merges in column name hash as expected" do
          expect(mapper.hash.map { |src, h| h[:column_name] }).to eq(
            %w[objectNameControlledConceptNomenclature
              objectNameControlledRefname]
          )
        end
      end

      describe "#mappings" do
        it "returns 2 mappings" do
          expect(mapper.mappings.size).to eq(2)
        end
      end

      describe "#get_transforms" do
        it "creates transform hashes as expected" do
          rh = mapper.hash.map { |src, h| h[:transforms] }
          expected = [
            {authority: %w[conceptauthorities nomenclature]},
            {}
          ]
          expect(rh).to eq(expected)
        end
      end

      describe "#source_type" do
        it "returns authority" do
          expect(mapper.source_type).to eq("authority")
        end
      end
    end
  end

  context "when stuctured date field" do
    let(:fieldrec) { "collectionobject" }
    let(:fieldname) { "assocStructuredDateGroup" }

    describe "#get_data_columns" do
      it "merges in column name hash as expected" do
        expect(mapper.hash.map do |src, h|
                 h[:column_name]
               end).to eq(%w[assocStructuredDateGroup])
      end
    end
    describe "#mappings" do
      it "returns 1 mappings" do
        expect(mapper.mappings.size).to eq(1)
      end
    end
    describe "#get_transforms" do
      it "creates transform hashes as expected" do
        rh = mapper.hash.map { |src, h| h[:transforms] }
        expected = [
          {}
        ]
        expect(rh).to eq(expected)
      end
    end
    describe "#source_type" do
      it "returns na" do
        expect(mapper.source_type).to eq("na")
      end
    end
  end

  context "when boolean field" do
    let(:fieldrec) { "concept" }
    let(:fieldname) { "termPrefForLang" }

    describe "#get_transforms" do
      it "creates transform hashes as expected" do
        rh = mapper.hash.map { |src, h| h[:transforms] }
        expected = [
          {special: %w[boolean]}
        ]
        expect(rh).to eq(expected)
      end
    end
  end

  context "when behrensmeyer field" do
    let(:profilename) { "anthro" }
    let(:fieldrec) { "collectionobject" }
    let(:fieldname) { "behrensmeyerUpper" }

    describe "#get_transforms" do
      it "creates transform hashes as expected" do
        rh = mapper.hash.map { |src, h| h[:transforms] }
        expected = [
          {special: %w[behrensmeyer_translate],
           vocabulary: "behrensmeyer"},
          {}
        ]
        expect(rh).to eq(expected)
      end
    end
  end
end
