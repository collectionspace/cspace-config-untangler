# frozen_string_literal: true

require "spec_helper"

RSpec.describe CCU::MessageId, :aggregate_failures do
  subject { described_class.new(id) }

  context "when about type" do
    let(:id) { "about.title" }

    it "returns expected values" do
      expect(subject.element_type).to eq(:about)
      expect(subject.base_id).to eq(id)
      expect(subject.message_type).to eq(:label)
    end
  end

  context "when record type" do
    let(:id) { "record.movement.collectionName" }

    it "returns expected values" do
      expect(subject.element_type).to eq(:record)
      expect(subject.base_id).to eq("record.movement")
      expect(subject.message_type).to eq(:collectionName)
      expect(subject.element_name).to eq("movement")
    end
  end

  context "when field type" do
    context "with regular namespace" do
      let(:id) { "field.collectionobjects_common.objectNumber.name" }

      it "returns expected values" do
        expect(subject.element_type).to eq(:field)
        expect(subject.base_id).to eq(
          "field.collectionobjects_common.objectNumber"
        )
        expect(subject.message_type).to eq(:name)
        expect(subject.element_name).to eq("objectNumber")
      end
    end

    context "with object assocCulturalContext" do
      let(:id) do
        "field.collectionobjects_common.assocCulturalContext.fullName"
      end

      it "returns expected values" do
        expect(subject.element_type).to eq(:field)
        expect(subject.base_id).to eq(
          "field.collectionobjects_common.assocCulturalContext"
        )
        expect(subject.message_type).to eq(:fullName)
        expect(subject.element_name).to eq("assocCulturalContext")
      end
    end

    context "with ext namespace" do
      let(:id) { "field.ext.associatedAuthority.assocPersonType.fullName" }

      it "returns expected values" do
        expect(subject.element_type).to eq(:field)
        expect(subject.base_id).to eq(
          "field.ext.associatedAuthority.assocPersonType"
        )
        expect(subject.message_type).to eq(:fullName)
        expect(subject.element_name).to eq("assocPersonType")
      end
    end

    context "when from livingplant extension field definitions" do
      let(:id) { "field.conservation_livingplant.fertilizerUsed.name" }

      it "returns expected values" do
        expect(subject.element_type).to eq(:field)
        expect(subject.base_id).to eq(
          "field.conservation_livingplant.fertilizerUsed"
        )
        expect(subject.normalized_base_id).to eq(
          "field.ext.livingplant.fertilizerUsed"
        )
        expect(subject.message_type).to eq(:name)
        expect(subject.element_name).to eq("fertilizerUsed")
      end
    end

    context "when nadme instead of name" do
      let(:id) { "field.conservation_common.sampleReturned.nadme" }

      it "returns expected values" do
        expect(subject.normalized_id).to eq(
          "field.conservation_common.sampleReturned.name"
        )
        expect(subject.message_type).to eq(:name)
      end
    end
  end

  context "when form type" do
    let(:id) { "form.collectionobject.default.name" }

    it "returns expected values" do
      expect(subject.element_type).to eq(:form)
      expect(subject.base_id).to eq(
        "form.collectionobject.default"
      )
      expect(subject.message_type).to eq(:name)
      expect(subject.element_name).to eq("default")
    end
  end

  context "when panel type" do
    let(:id) { "panel.loanout.info" }

    it "returns expected values" do
      expect(subject.element_type).to eq(:panel)
      expect(subject.base_id).to eq(id)
      expect(subject.message_type).to eq(:label)
      expect(subject.element_name).to eq("info")
    end
  end

  context "when panel type, but is actually for an input table" do
    let(:id) { "panel.collectionobject.fruits" }

    it "returns expected values" do
      expect(subject.element_type).to eq(:inputTable)
      expect(subject.base_id).to eq("panel.collectionobject.fruits")
      expect(subject.normalized_base_id).to eq(
        "inputTable.collectionobject.fruits"
      )
      expect(subject.message_type).to eq(:label)
      expect(subject.element_name).to eq("fruits")
    end
  end

  context "when inputTable type" do
    let(:id) { "inputTable.collectionobject.assocEvent" }

    it "returns expected values" do
      expect(subject.element_type).to eq(:inputTable)
      expect(subject.base_id).to eq(id)
      expect(subject.message_type).to eq(:label)
      expect(subject.element_name).to eq("assocEvent")
    end
  end

  context "when column type" do
    let(:id) { "column.chronology.default.termDisplayName" }

    it "returns expected values" do
      expect(subject.element_type).to eq(:column)
      expect(subject.base_id).to eq("column.chronology.termDisplayName")
      expect(subject.message_type).to eq(:default)
      expect(subject.element_name).to eq("termDisplayName")
    end
  end

  describe "#match?" do
    let(:id) { "field.conservation_livingplant.fertilizerUsed.name" }
    let(:result) { subject.match?(otherid) }

    context "with exact id match" do
      let(:otherid) { "field.conservation_livingplant.fertilizerUsed.name" }

      it "returns truthy" do
        expect(result).to be_truthy
      end
    end

    context "without exact id match" do
      let(:otherid) { "field.ext.livingplant.fertilizerUsed.name" }

      it "returns falsey" do
        expect(result).to be_falsey
      end
    end
  end

  describe "#norm_match?" do
    let(:id) { "field.conservation_livingplant.fertilizerUsed.name" }
    let(:result) { subject.norm_match?(otherid) }

    context "with exact id match" do
      let(:otherid) { "field.conservation_livingplant.fertilizerUsed.name" }

      it "returns truthy" do
        expect(result).to be_truthy
      end
    end

    context "with normalized id match" do
      let(:otherid) { "field.ext.livingplant.fertilizerUsed.name" }

      it "returns truthy" do
        expect(result).to be_truthy
      end
    end

    context "with no id match" do
      let(:otherid) { "field.ext.livingplant.fertilizerUsed.fullName" }

      it "returns falsey" do
        expect(result).to be_falsey
      end
    end
  end

  describe "#base_match?" do
    let(:id) { "field.conservation_livingplant.fertilizerUsed.name" }
    let(:result) { subject.base_match?(otherid) }

    context "with exact base id match" do
      let(:otherid) { "field.conservation_livingplant.fertilizerUsed.fullName" }

      it "returns truthy" do
        expect(result).to be_truthy
      end
    end

    context "without exact base id match" do
      let(:otherid) { "field.ext.livingplant.fertilizerUsed.fullName" }

      it "returns falsey" do
        expect(result).to be_falsey
      end
    end
  end

  describe "#norm_base_match?" do
    let(:id) { "field.conservation_livingplant.fertilizerUsed.name" }
    let(:result) { subject.norm_base_match?(otherid) }

    context "with exact base id match" do
      let(:otherid) { "field.conservation_livingplant.fertilizerUsed.fullName" }

      it "returns truthy" do
        expect(result).to be_truthy
      end
    end

    context "with normalized livingplant base id match" do
      let(:otherid) { "field.ext.livingplant.fertilizerUsed.fullName" }

      it "returns truthy" do
        expect(result).to be_truthy
      end
    end

    context "with normalized hoursSpent base id match" do
      let(:id) { "field.uoc_common.hoursSpent.name" }
      let(:otherid) { "field.uoc_common.useDateHoursSpent.fullName" }

      it "returns truthy" do
        expect(result).to be_truthy
      end
    end

    context "with normalized compressionstandard base id match" do
      let(:id) { "field.collectionobjects_common.compressionstandard.name" }
      let(:otherid) do
        "field.collectionobjects_common.compressionStandard.fullName"
      end

      it "returns truthy" do
        expect(result).to be_truthy
      end
    end

    context "without normalized base id match" do
      let(:otherid) { "field.ext.livingplant.otherFieldName.fullName" }

      it "returns falsey" do
        expect(result).to be_falsey
      end
    end
  end
end
