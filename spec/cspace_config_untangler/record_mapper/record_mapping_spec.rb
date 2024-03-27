# frozen_string_literal: true

require "spec_helper"

RSpec.describe CCU::RecordMapper::RecordMapping do
  let(:generator) {
    Helpers::SetupGenerator.new(profile: profilename, rectypes: rectypes,
      release: release)
  }
  let(:profilename) { "core" }
  let(:rectypes) { ["collectionobject", "concept", "movement"] }
  let(:release) { "6_1" }
  let(:profile) { generator.profile }

  describe RecordMapping do
    let(:mapper) { generator.record_mapping }
    let(:config) { mapper.hash[:config] }
    context "when botgarden profile" do
      let(:profilename) { "botgarden" }

      context "when loanout rectype" do
        let(:rectypes) { ["loanout"] }

        it "service_type = procedure" do
          expect(config[:service_type]).to eq("procedure")
        end
        it "identifier_field = loanOutNumber" do
          expect(config[:identifier_field]).to eq("loanOutNumber")
        end
      end

      context "when pottag rectype" do
        let(:rectypes) { ["pottag"] }

        it "service_type = procedure" do
          expect(config[:service_type]).to eq("procedure")
        end
        it "identifier_field = potTagNumber" do
          expect(config[:identifier_field]).to eq("potTagNumber")
        end
      end
    end

    context "when fcart profile" do
      let(:profilename) { "fcart" }

      context "when movement rectype" do
        let(:rectypes) { ["movement"] }

        it "service_type = procedure" do
          expect(config[:service_type]).to eq("procedure")
        end
        it "identifier_field = movementReferenceNumber" do
          expect(config[:identifier_field]).to eq("movementReferenceNumber")
        end
      end
    end

    context "when anthro profile" do
      let(:profilename) { "anthro" }

      context "when collectionobject rectype" do
        let(:rectypes) { ["collectionobject"] }

        it "service_type = object" do
          expect(config[:service_type]).to eq("object")
        end
        it "identifier_field = objectNumber" do
          expect(config[:identifier_field]).to eq("objectNumber")
        end
      end

      context "when claim rectype" do
        let(:rectypes) { ["claim"] }

        it "service_type = procedure" do
          expect(config[:service_type]).to eq("procedure")
        end
        it "identifier_field = claimNumber" do
          expect(config[:identifier_field]).to eq("claimNumber")
        end
      end

      context "when osteology rectype" do
        let(:rectypes) { ["osteology"] }

        it "service_type = procedure" do
          expect(config[:service_type]).to eq("procedure")
        end
        it "identifier_field = InventoryID" do
          expect(config[:identifier_field]).to eq("InventoryID")
        end
      end

      context "when taxon rectype" do
        let(:rectypes) { ["taxon"] }

        it "service_type = authority" do
          expect(config[:service_type]).to eq("authority")
        end
        it "identifier_field = shortIdentifier" do
          expect(config[:identifier_field]).to eq("shortIdentifier")
        end
        it "[:authority_subtypes] returns array of hashes with keys: name, servicepathname" do
          subtypes = config[:authority_subtypes]
          expected = [
            {name: "Local", subtype: "taxon"},
            {name: "Common", subtype: "common_ta"}
          ]
          expect(subtypes).to eq(expected)
        end
      end
    end
  end
end
