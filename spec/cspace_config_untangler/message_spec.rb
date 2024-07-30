# frozen_string_literal: true

require "spec_helper"

RSpec.describe CCU::Message, :aggregate_failures do
  subject { described_class.new(config, parent: parent) }

  let(:parent) { nil }

  context "with no parent" do
    let(:config) do
      {
        "id" => "record.collectionobject.name",
        "defaultMessage" => "Object"
      }
    end

    it "returns expected values" do
      expect(subject.full_id).to eq("record.collectionobject.name")
      expect(subject.element_type).to eq(:record)
      expect(subject.base_id).to eq("record.collectionobject")
      expect(subject.message_type).to eq(:name)
      expect(subject.element_name).to eq("collectionobject")
      expect(subject.message).to eq("Object")
    end
  end

  context "with parent having CompoundInput view type" do
    let(:config) do
      {
        "id" => "field.collectionobjects_common.otherNumber.name",
        "defaultMessage" => "Other number"
      }
    end
    let(:parent) do
      {"[config]" => {
        "view" => {
          "type" => "CompoundInput"
        }
      }}
    end

    it "returns expected values" do
      expect(subject.element_type).to eq(:field_grouping)
    end
  end
end
