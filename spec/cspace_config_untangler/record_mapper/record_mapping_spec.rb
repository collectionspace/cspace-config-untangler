# frozen_string_literal: true

require "spec_helper"

RSpec.describe CCU::RecordMapper::RecordMapping do
  let(:generator) do
    Helpers::SetupGenerator.new(profile: profilename, rectypes: rectypes,
      release: release)
  end
  let(:profilename) { "core" }
  let(:rectypes) { ["collectionobject", "concept", "movement"] }
  let(:release) { "8_1" }
  let(:profile) { generator.profile }

  describe RecordMapping do
    let(:subtype) { nil }
    let(:style) { :csvimporter }
    let(:mapper) { generator.record_mapping(subtype, style) }
    let(:config) { mapper[:config] }
    let(:mappings) { mapper[:mappings] }
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
        it "has no display_name" do
          expect(config.key?(:display_name)).to be false
        end
        it "has no dataConfigType" do
          expect(config.key?(:dataConfigType)).to be false
        end
        it "generates multi-columns for authority controlled field" do
          res = mappings.select { |m| m[:fieldname] == "currentLocation" }
            .map { |m| m[:datacolumn] }
            .sort
          exp = %w[currentLocationLocationLocal currentLocationLocationOffsite
            currentLocationOrganizationLocal currentLocationPlaceLocal
            currentLocationRefname].sort
          expect(res).to eq(exp)
        end

        context "when style == :datatoolkit" do
          let(:style) { :datatoolkit }

          it "has display_name" do
            expect(config[:display_name]).to eq("Location/Movement/Inventory")
          end
          it "has dataConfigType" do
            expect(config[:dataConfigType]).to eq("record type")
          end
          it "generates column pair for authority controlled field" do
            res = mappings.select { |m| m[:fieldname] == "currentLocation" }
              .map { |m| m[:datacolumn] }
              .sort
            exp = %w[currentLocation currentLocationAuthorityVocabulary].sort
            expect(res).to eq(exp)
          end
          it "paired authority vocab field indicates field value sources" do
            res = mappings.find do |m|
              m[:datacolumn] == "currentLocationAuthorityVocabulary"
            end
            exp = ["Location/Local", "Location/Offsite", "Organization/Local",
              "Place/Local"].sort
            expect(res[:opt_list_values].sort).to eq(exp)
          end
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
        it "[:authority_subtypes] returns array of hashes with keys: name, "\
          "servicepathname" do
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
