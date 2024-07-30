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
end
