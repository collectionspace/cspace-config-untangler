# frozen_string_literal: true

require "spec_helper"

RSpec.describe CCU::Forms::Props do
  subject(:props) { described_class.new(form, config, parent) }

  let(:release) { "8_0" }
  let(:profilename) { "anthro" }
  let(:rectypes) { ["collectionobject"] }
  let(:generator) {
    Helpers::SetupGenerator.new(profile: profilename, rectypes: rectypes,
      release: release)
  }
  let(:templatename) { "default" }
  let(:form) { generator.form(templatename) }
  let(:formconfig) { form.field_config }
  let(:parent) { nil }

  describe "#children?" do
    let(:result) { props.children? }

    context "with children" do
      let(:config) { formconfig.dig("children", 2, "props") }

      it "returns true" do
        expect(result).to be true
      end
    end

    context "without children (descriptionLevel)" do
      let(:config) {
        formconfig.dig("children", 0, "props", "children",
          0, "props", "children", 0, "props", "children", 4, "props")
      }
      it "returns falsey" do
        expect(result).to be_falsey
      end
    end
  end

  describe "#contact?" do
    let(:rectypes) { ["organization"] }
    let(:result) { props.contact? }

    context "when a contact" do
      let(:config) { formconfig["children"][1]["props"] }
      it "returns true" do
        expect(result).to be true
      end
    end

    context "when not a contact" do
      let(:config) { formconfig["children"][0]["props"] }
      it "returns falsey" do
        expect(result).to be_falsey
      end
    end
  end

  describe "#panel" do
    let(:result) { props.panel }

    context "when a panel" do
      let(:config) { formconfig.dig("children", 2, "props") }
      it "returns panel id" do
        expect(result).to eq("panel.collectionobject.prod")
      end
    end

    context "when child of a panel" do
      let(:config) do
        formconfig.dig("children", 2, "props", "children", "props", "children",
          0, "props")
      end
      let(:parent) do
        described_class.new(form, formconfig.dig("children", 2, "props"))
      end
      it "returns parent's panel id" do
        expect(result).to eq("panel.collectionobject.prod")
      end
    end
  end

  describe "#panel?" do
    let(:result) { props.panel? }

    context "when a panel" do
      let(:config) { formconfig["children"][2]["props"] }
      it "returns true" do
        expect(result).to be true
      end
    end

    context "when not a panel" do
      let(:config) do
        formconfig.dig("children", 2, "props", "children", "props", "children",
          0, "props")
      end
      it "returns falsey" do
        expect(result).to be_falsey
      end
    end
  end
end
