# frozen_string_literal: true

require "spec_helper"

RSpec.describe CCU::Forms::Props do
  subject(:props) do
    iter = CCU::Forms::IterativeFieldExtractor.new(form, formconfig)

    iter.call
    iter.send(:allprops).select { |p| p.name == name }.first
  end

  let(:release) { "8_0" }
  let(:profilename) { "anthro" }
  let(:rectypes) { ["collectionobject"] }
  let(:generator) do
    Helpers::SetupGenerator.new(profile: profilename, rectypes:,
      release:)
  end
  let(:templatename) { "default" }
  let(:form) { generator.form(templatename) }
  let(:formconfig) { form.field_config }

  describe "#address?" do
    let(:rectypes) { ["place"] }
    let(:result) { props.address? }

    context "when address group list" do
      let(:name) { "addrGroupList" }

      it "returns true" do
        expect(result).to be true
      end
    end

    context "when address group" do
      let(:name) { "addrGroup" }

      it "returns true" do
        expect(result).to be true
      end
    end

    context "when addressPlace1" do
      let(:name) { "addressPlace1" }

      it "returns true" do
        expect(result).to be true
      end
    end

    context "when placeNote" do
      let(:name) { "placeNote" }

      it "returns false" do
        expect(result).to be_falsey
      end
    end
  end

  describe "#children?" do
    let(:result) { props.children? }

    context "with children" do
      let(:name) { "ethnoFileCodes" }

      it "returns true" do
        expect(result).to be true
      end
    end

    context "without children (descriptionLevel)" do
      let(:name) { "descriptionLevel" }

      it "returns falsey" do
        expect(result).to be_falsey
      end
    end
  end

  describe "#contact?" do
    let(:rectypes) { ["organization"] }
    let(:result) { props.contact? }

    context "when a contact" do
      let(:name) { "contact" }

      it "returns true" do
        expect(result).to be true
      end
    end

    context "when child of contact" do
      let(:name) { "emailType" }

      it "returns falsey" do
        expect(result).to be_falsey
      end
    end

    context "when not a contact" do
      let(:name) { "nameNote" }

      it "returns falsey" do
        expect(result).to be_falsey
      end
    end
  end

  describe "#extension?" do
    let(:result) { props.extension? }

    context "when prop represents a form panel with same name as a profile "\
      "extension (anthro collectionobject locality)" do
        let(:name) { "locality" }

        it "returns true" do
          expect(result).to be true
        end
      end

    context "when prop is a form panel that is not an extension" do
      let(:name) { "reference" }

      it "returns false" do
        expect(result).to be_falsey
      end
    end

    context "when prop does not represent a form panel" do
      let(:name) { "descriptionLevel" }

      it "returns falsey" do
        expect(result).to be_falsey
      end
    end
  end

  describe "#measurement?" do
    let(:profilename) { "fcart" }
    let(:result) { props.measurement? }

    context "when prop is measuredPartGroupList" do
      let(:name) { "measuredPartGroupList" }

      it "returns true" do
        expect(result).to be true
      end
    end

    context "when prop is child of a measurement" do
      let(:name) { "dimensionSummary" }

      it "returns true" do
        expect(result).to be true
      end
    end

    context "when prop does not represent a field from measurement ext" do
      let(:name) { "descriptionLevel" }

      it "returns falsey" do
        expect(result).to be_falsey
      end
    end
  end

  describe "#ns" do
    let(:result) { props.ns }

    # anthro collectionobject locality
    context "with panel that is an extension" do
      let(:name) { "locality" }

      it "returns correct ns" do
        expect(result).to eq("ns2:collectionobjects_common")
      end
    end

    # anthro collectionobject localityGroupList
    context "with child of panel that is an extension" do
      let(:name) { "localityGroupList" }

      it "returns correct ns" do
        expect(result).to eq("ns2:collectionobjects_anthro")
      end
    end

    context "with array subpath overriding repeating field group" do
      let(:profilename) { "materials" }
      let(:name) { "objectCount" }

      it "returns correct ns" do
        expect(result).to eq("ns2:collectionobjects_common")
      end
    end
  end

  describe "#ns_for_id" do
    let(:result) { props.ns_for_id }
    let(:profilename) { "fcart" }

    context "with fcart collectionobject measuredPartGroupList" do
      let(:name) { "measuredPartGroupList" }

      it "returns correct ns" do
        expect(result).to eq("ext.measurement")
      end
    end

    context "with child of ext ns" do
      let(:name) { "dimensionSummary" }

      it "returns correct ns" do
        expect(result).to eq("ext.measurement")
      end
    end

    context "with non-contact address" do
      let(:rectypes) { ["place"] }
      let(:name) { "addressPlace1" }

      it "returns correct ns" do
        expect(result).to eq("ext.address")
      end
    end

    context "with contact address" do
      let(:rectypes) { ["organization"] }
      let(:name) { "addressPlace1" }

      it "returns correct ns" do
        expect(result).to eq("ns2:contacts_common")
      end
    end

    context "with ns2:collectionobjects_accessionattributes" do
      let(:profilename) { "botgarden" }
      let(:name) { "flowerColor" }

      it "returns correct ns" do
        expect(result).to eq("ext.accessionattributes")
      end
    end

    context "with ns2:collectionobjects_accessionuse" do
      let(:profilename) { "botgarden" }
      let(:name) { "accessionUseType" }

      it "returns correct ns" do
        expect(result).to eq("ext.accessionuse")
      end
    end

    context "with ns2:collectionobjects_fineart" do
      let(:profilename) { "fcart" }
      let(:name) { "materialTechniqueDescription" }

      it "returns correct ns" do
        expect(result).to eq("ext.fineart")
      end
    end

    context "with ns2:acquisitions_commission" do
      let(:profilename) { "publicart" }
      let(:rectypes) { ["acquisition"] }
      let(:name) { "commissioningBody" }

      it "returns correct ns" do
        expect(result).to eq("ext.commission")
      end
    end

    context "with ns2:collectionobjects_variablemedia" do
      let(:profilename) { "fcart" }

      context "when field name begins with `contentWork`" do
        let(:name) { "contentWorkType" }

        it "returns correct ns" do
          expect(result).to eq("ext.contentWorks")
        end
      end

      context "when field name does not begin with `contentWork`" do
        let(:name) { "ratioFormat" }

        it "returns correct ns" do
          expect(result).to eq("ext.technicalSpecs")
        end
      end
    end
  end

  describe "#panel" do
    let(:result) { props.panel }

    context "when a panel" do
      let(:name) { "prod" }

      it "returns panel id" do
        expect(result).to eq("panel.collectionobject.prod")
      end
    end

    context "when child of a panel" do
      let(:name) { "objectProductionDateGroupList" }

      it "returns parent's panel id" do
        expect(result).to eq("panel.collectionobject.prod")
      end
    end
  end

  describe "#panel?" do
    let(:rectypes) { ["acquisition"] }
    let(:result) do
      puts "parent: #{props.parent.name}"
      props.panel?
    end

    context "when a panel" do
      let(:name) { "info" }

      it "returns true" do
        expect(result).to be true
      end
    end

    context "when a not-first-level panel" do
      let(:name) { "priceInformation" }

      it "returns falsey" do
        expect(result).to be_falsey
      end
    end

    context "when not a panel" do
      let(:name) { "objectPurchasePriceCurrency" }

      it "returns falsey" do
        expect(result).to be_falsey
      end
    end
  end

  describe "#formatted_ui_path" do
    let(:result) { props.formatted_ui_path }

    context "with array subpath overriding repeating field group" do
      let(:profilename) { "materials" }
      let(:name) { "objectCount" }

      it "returns path" do
        expect(result).to eq("ns2:collectionobjects_common / "\
                             "objectCountGroupList / objectCountGroup")
      end
    end
  end
end
