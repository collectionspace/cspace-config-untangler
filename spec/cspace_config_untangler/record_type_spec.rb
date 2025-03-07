# frozen_string_literal: true

require "spec_helper"

RSpec.describe CCU::RecordType do
  let(:release) { "7_0" }
  let(:generator) do
    Helpers::SetupGenerator.new(profile: profilename, rectypes: rectypes,
      release: release)
  end
  let(:profilename) { "core" }
  let(:rectypes) { %w[collectionobject] }
  let(:profile) { generator.profile }
  let(:rectype) { generator.rectype }

  it "creates CCU::RecordType object" do
    expect(rectype).to be_instance_of(CCU::RecordType)
  end

  describe "#service_type" do
    let(:result) { rectype.service_type }
    context "when collectionobject" do
      it "returns object" do
        expect(result).to eq("object")
      end
    end

    context "when media" do
      let(:rectypes) { %w[media] }
      it "returns procedure" do
        expect(result).to eq("procedure")
      end
    end

    context "when person" do
      let(:rectypes) { %w[person] }
      it "returns authority" do
        expect(result).to eq("authority")
      end
    end
  end

  describe "#subtypes" do
    let(:result) { rectype.subtypes }
    context "when collectionobject" do
      it "returns empty Array" do
        expect(result).to eq([])
      end
    end

    context "when media" do
      let(:rectypes) { %w[media] }
      it "returns empty Array" do
        expect(result).to eq([])
      end
    end

    context "when person" do
      let(:rectypes) { %w[person] }
      it "sets subtypes attribute as expected" do
        expected = [
          {
            name: "Local",
            subtype: "person"
          },
          {
            name: "ULAN",
            subtype: "ulan_pa"
          }
        ]
        expect(result).to eq(expected)
      end
    end
  end

  describe "#id_field" do
    let(:result) { rectype.id_field }
    context "when anthro profile" do
      let(:profilename) { "anthro" }
      context "when movement rectype" do
        let(:rectypes) { %w[movement] }
        it "returns movementReferenceNumber" do
          expect(result).to eq("movementReferenceNumber")
        end
      end
    end
  end

  describe ".panels" do
    let(:result) { rectype.panels.sort }
    context "when anthro profile" do
      let(:profilename) { "anthro" }
      context "when collectionobject" do
        it "returns array" do
          expect(result).to be_a(Array)
        end
        it "includes all panel names for rectype" do
          panels = [
            "id", "desc", "content", "textInscript",
            "nonTextInscript", "prod", "hist", "assoc", "owner",
            "viewer", "reference", "collect", "hierarchy", "bio",
            "commingledRemains", "locality", "culturalCare",
            "georefDetail", "nagpraCompliance"
          ].sort
          expect(result).to eq(panels)
        end
      end
    end
  end

  describe ".input_tables" do
    let(:result) { rectype.input_tables }
    context "when anthro profile" do
      let(:profilename) { "anthro" }
      context "when collectionobject" do
        it "returns hash" do
          expect(result).to be_a(Hash)
        end
        it "keys are the panel names for rectype" do
          panels = [
            "age", "assocEvent", "ownershipExchange", "behrensmeyer",
            "depth", "elevation", "distanceAboveSurface",
            "nagpraReportFiled", "taxonName", "taxonIdent",
            "taxonReference"
          ].sort
          expect(result.keys.sort).to eq(panels)
        end
      end
    end
  end

  describe ".forms" do
    let(:result) { rectype.forms }
    context "when anthro profile" do
      let(:profilename) { "anthro" }
      context "when collectionobject" do
        it "returns hash" do
          expect(result).to be_a(Hash)
        end
        it "hash keys are the form names" do
          forms = %w[default inventory photo].sort
          expect(result.keys.sort).to eq(forms)
        end

        it "hash values are CCU::Form objects" do
          expect(result["default"]).to be_a(CCU::Form)
        end
      end
    end
  end

  describe ".ns" do
    let(:result) { rectype.ns }
    let(:release) { "8_1" }

    context "when botgarden profile" do
      let(:profilename) { "botgarden" }

      context "when collectionobject" do
        it "returns correct namespace" do
          expect(result).to eq("ns2:collectionobjects_common")
        end
      end

      context "when loanout" do
        let(:rectypes) { ["loanout"] }

        it "returns correct namespace" do
          expect(result).to eq("ns2:loansout_common")
        end
      end
    end

    context "when UCBG profile" do
      let(:release) {"lyr"}
      let(:profilename) { "ucbg_3-0-0-rc-2" }

      context "when loanout" do
        let(:rectypes) { ["loanout"] }
        it "returns correct namespace" do
          expect(result).to eq("ns2:loansout_common")
        end
      end
    end
  end

  describe "#mappings" do
    let(:result) { rectype.mappings }
    let(:columns) do
      result.select do |m|
        m.fieldname == fieldname
      end.map { |m| m.datacolumn }.sort
    end
    context "anthro profile" do
      let(:profilename) { "anthro" }
      context "collectionobject recordtype" do
        context "fieldname = sex" do
          let(:fieldname) { "sex" }
          it "columnnames: sex, commingledRemainsGroup_sex" do
            expect(columns).to eq(%w[commingledRemainsGroup_sex sex])
          end
        end
        context "fieldname = reference" do
          let(:fieldname) { "reference" }

          # does NOT change datacolumn values, as one field's use of
          #  multiple authorities has already caused all datacolumn
          #  values to be different
          it "columnnames: reference referenceCitationLocal "\
            "referenceCitationWorldcat" do
            expect(columns).to eq(%w[reference referenceCitationLocal
              referenceCitationWorldcat referenceRefname])
          end
        end
        context "fieldname = fieldLocVerbatim" do
          let(:fieldname) { "fieldLocVerbatim" }
          it "columnnames: fieldLocVerbatim localityGroup_fieldLocVerbatim" do
            expect(columns).to eq(%w[fieldLocVerbatim
              localityGroup_fieldLocVerbatim])
          end
        end
      end

      context "when movement recordtype" do
        let(:rectypes) { %w[movement] }
        let(:required) do
          result.select do |m|
            m.fieldname == fieldname
          end.map { |m| m.required }.sort
        end
        context "with fieldname = movementReferenceNumber" do
          let(:fieldname) { "movementReferenceNumber" }
          it "is not required" do
            expect(required).to eq(%w[n])
          end
        end
      end
    end
  end

  describe "#fields" do
    let(:result) { rectype.fields }
    context "core profile" do
      context "media recordtype" do
        let(:rectypes) { %w[media] }

        it "returns array of CCU::Fields::Field objects" do
          expect(result).to be_a(Array)
          expect(result.first).to be_a(CCU::Fields::Field)
        end

        it "includes mediaFileURI field" do
          uri_field = result.select { |f| f.name == "mediaFileURI" }
          expect(uri_field.length).to eq(1)
        end
      end
    end
  end

  describe "#batch_mappings" do
    context "with context = :mapper" do
      let(:result) { rectype.batch_mappings }
      context "anthro profile" do
        let(:profilename) { "anthro" }
        context "collectionobject" do
          it "removes computedCurrentLocation mappings" do
            check = result.select do |m|
              m.fieldname == "computedCurrentLocation"
            end
            expect(check).to be_empty
          end
        end

        context "media" do
          let(:rectypes) { %w[media] }
          it "removes mediaFileURI mappings" do
            check = result.select { |m| m.fieldname == "mediaFileURI" }
            expect(check).to be_empty
          end
        end

        context "movement recordtype" do
          let(:rectypes) { %w[movement] }
          it "movementReferenceNumber is required" do
            check = result.select do |m|
                      m.fieldname == "movementReferenceNumber"
                    end.map { |m| m.required }.sort
            expect(check).to eq(%w[y])
          end
        end
      end
    end

    context "with context = :template" do
      let(:result) { rectype.batch_mappings(:template) }
      context "anthro profile" do
        let(:profilename) { "anthro" }
        context "collectionobject" do
          it "removes computedCurrentLocation mappings" do
            check = result.select do |m|
              m.fieldname == "computedCurrentLocation"
            end
            expect(check).to be_empty
          end
        end

        context "media" do
          let(:rectypes) { %w[media] }
          it "keeps mediaFileURI mappings" do
            check = result.select { |m| m.fieldname == "mediaFileURI" }
            expect(check.length).to eq(1)
          end
        end

        context "movement recordtype" do
          let(:rectypes) { %w[movement] }
          it "movementReferenceNumber is required" do
            check = result.select do |m|
                      m.fieldname == "movementReferenceNumber"
                    end.map { |m| m.required }.sort
            expect(check).to eq(%w[y])
          end
        end
      end
    end
  end
end
