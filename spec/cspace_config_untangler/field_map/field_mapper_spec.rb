# frozen_string_literal: true

require "spec_helper"

RSpec.describe CCU::FieldMap::FieldMapper do
  let(:generator) do
    Helpers::SetupGenerator.new(profile: profilename, rectypes: rectypes,
      release: release)
  end
  let(:profilename) { "core" }
  let(:rectypes) { ["collectionobject", "concept", "movement"] }
  let(:release) { "7_0" }
  let(:profile) { generator.profile }
  let(:field) { generator.field(fieldrec, fieldname) }
  let(:column_style) { :fully_consistent }
  let(:mapper) { FieldMapper.new(field: field, column_style: column_style) }

  context "when no field source" do
    let(:fieldrec) { "collectionobject" }
    let(:fieldname) { "assocActivity" }

    describe "#columns" do
      it "column is the same as field name" do
        expect(mapper.columns.map do |src, h|
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

    context "and when data_toolkit for 8.3" do
      let(:release) { "8_3" }
      let(:column_style) { :datatoolkit }

      describe "#columns" do
        it "column is the same as field name" do
          expect(mapper.columns.map do |src, h|
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
  end

  context "when field source is option list" do
    let(:fieldrec) { "collectionobject" }
    let(:fieldname) { "ageUnit" }

    describe "#columns" do
      it "column is the same as field name" do
        chk = mapper.columns.map { |src, h| h[:column_name] }
        expect(chk).to eq(["ageUnit"])
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

    context "and when data_toolkit for 8.3" do
      let(:release) { "8_3" }
      let(:column_style) { :datatoolkit }

      describe "#columns" do
        it "column is the same as field name" do
          chk = mapper.columns.map { |src, h| h[:column_name] }
          expect(chk).to eq(["ageUnit"])
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
  end

  context "when field source is vocabulary" do
    context "we assume only one vocabulary source per field" do
      let(:fieldrec) { "collectionobject" }
      let(:fieldname) { "ageQualifier" }

      describe "#columns" do
        it "column is the same as field name" do
          expect(mapper.columns.map do |src, h|
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
          rh = mapper.columns.map { |src, h| h[:transforms] }
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

      context "and when data_toolkit for 8.3" do
        let(:release) { "8_3" }
        let(:column_style) { :datatoolkit }

        describe "#columns" do
          it "column is the same as field name" do
            expect(mapper.columns.map do |src, h|
                     h[:column_name]
                   end).to eq(["ageQualifier"])
          end
        end

        describe "#mappings" do
          it "returns 1 mapping" do
            expect(mapper.mappings.size).to eq(1)
          end
        end

        describe "#get_transforms" do
          it "creates transform hash as expected" do
            rh = mapper.columns.map { |src, h| h[:transforms] }
            expected = [
              {vocabulary: "agequalifier"}
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
  end

  context "when field source is authority" do
    context "and two authorities may be used" do
      let(:fieldrec) { "collectionobject" }
      let(:fieldname) { "contentConcept" }

      describe "#columns" do
        it "merges in column name hash as expected" do
          expect(mapper.columns.map { |src, h| h[:column_name] }).to eq(
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
          rh = mapper.columns.map { |src, h| h[:transforms] }
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

      context "and when data_toolkit for 8.3" do
        let(:release) { "8_3" }
        let(:column_style) { :datatoolkit }

        describe "#columns" do
          it "merges in column name hash as expected" do
            expect(mapper.columns.map { |src, h| h[:column_name] }).to eq(
              %w[contentConcept contentConceptAuthorityVocabulary]
            )
          end
        end

        describe "#mappings" do
          it "returns expected mappings" do
            result = mapper.mappings
            expect(result.size).to eq(2)
            expect(result.first.datacolumn).to eq("contentConcept")
            expect(result.first.source_name).to be_nil
            expect(result.first.source_type).to eq("authority")
            expect(result.first.transforms[:authority].last).to eq("concept")
            expect(result.last.datacolumn).to eq(
              "contentConceptAuthorityVocabulary"
            )
            expect(result.last.source_name).to be_nil
            expect(result.last.source_type).to eq(
              "authority vocabulary indication"
            )
            expect(result.last.opt_list_values).to eq([
              "Concept/Associated", "Concept/Material"
            ])
          end
        end

        describe "#source_type" do
          it "returns authority" do
            expect(mapper.source_type).to eq("authority")
          end
        end
      end
    end

    context "and one authority may be used, 8.0 or after" do
      let(:release) { "8_0" }
      let(:fieldrec) { "collectionobject" }
      let(:fieldname) { "objectNameControlled" }

      describe "#columns" do
        it "merges in column name hash as expected" do
          expect(mapper.columns.map { |src, h| h[:column_name] }).to eq(
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
          rh = mapper.columns.map { |src, h| h[:transforms] }
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

    describe "#columns" do
      it "merges in column name hash as expected" do
        expect(mapper.columns.map do |src, h|
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
        rh = mapper.columns.map { |src, h| h[:transforms] }
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
        rh = mapper.columns.map { |src, h| h[:transforms] }
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
        rh = mapper.columns.map { |src, h| h[:transforms] }
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
