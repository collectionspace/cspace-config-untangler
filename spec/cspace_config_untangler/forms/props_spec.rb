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

  describe "#address?" do
    let(:rectypes) { ["place"] }
    let(:result) { props.address? }

    context "when address group list" do
      let(:config) do
        formconfig.dig("children", 0, "props", "children", 4, "props")
      end

      it "returns true" do
        expect(result).to be true
      end
    end

    context "when address group", :pending do
      let(:config) do
        formconfig.dig("children", 0, "props", "children", 4, "props",
          "children", "props")
      end

      it "returns true" do
        expect(result).to be true
      end
    end

    context "when addressPlace1", :pending do
      let(:config) do
        formconfig.dig("children", 0, "props", "children", 4,
          "props", "children",
          "props", "children",
          "props", "children",
          "props", "children", 0,
          "props", "children", 0,
          "props")
      end

      it "returns true" do
        expect(result).to be true
      end
    end

    context "when placeNote" do
      let(:config) do
        formconfig.dig("children", 0, "props", "children", 3, "props")
      end

      it "returns false" do
        expect(result).to be_falsey
      end
    end
  end

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

  describe "#extension?" do
    let(:result) { props.extension? }

    context "when prop represents a form panel with same name as a profile "\
      "extension (anthro collectionobject locality)" do
        let(:config) { formconfig.dig("children", 10, "props") }

        it "returns true" do
          expect(result).to be true
        end
      end

    context "when prop is a form panel that is not an extension" do
      let(:config) { formconfig.dig("children", 9, "props") }

      it "returns false" do
        expect(result).to be_falsey
      end
    end

    context "when prop does not represent a form panel" do
      let(:config) do
        formconfig.dig("children", 0, "props", "children", 0, "props")
      end

      it "returns falsey" do
        expect(result).to be_falsey
      end
    end
  end

  describe "#ns" do
    let(:result) { props.ns }

    # anthro collectionobject locality
    context "with panel that is an extension" do
      let(:config) { formconfig.dig("children", 10, "props") }

      it "returns correct ns" do
        expect(result).to eq("ns2:collectionobjects_common")
      end
    end

    # anthro collectionobject localityGroupList
    context "with child of panel that is an extension" do
      let(:config) do
        formconfig.dig("children", 10, "props", "children", "props")
      end
      let(:parent) do
        described_class.new(form, formconfig.dig("children", 10, "props"))
      end

      it "returns correct ns" do
        expect(result).to eq("ns2:collectionobjects_anthro")
      end
    end

    # materials collectionobject objectCount (8_0)
    context "with array subpath overriding repeating field group" do
      let(:profilename) { "materials" }
      let(:config) do
        formconfig.dig("children", 0,
          "props", "children", 0,
          "props", "children", 0,
          "props", "children", 1,
          "props")
      end

      it "returns correct ns" do
        expect(result).to eq("ns2:collectionobjects_common")
      end
    end
  end

  describe "#ns_for_id" do
    let(:result) { props.ns_for_id }
    let(:profilename) { "fcart" }

    context "with fcart collectionobject measuredPartGroupList" do
      let(:config) do
        formconfig.dig("children", 2,
          "props", "children", 6,
          "props")
      end

      it "returns correct ns" do
        expect(result).to eq("ext.measurement")
      end
    end

    context "with child of ext ns" do
      let(:config) { formconfig.dig("children", 0, "props") }
      let(:parent) do
        Parent = Struct.new("Parent", :ns_for_id, :ui_path, :panel)
        Parent.new("ext.fake", [], false)
      end

      it "returns correct ns" do
        expect(result).to eq("ext.fake")
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
