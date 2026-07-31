# frozen_string_literal: true

require "spec_helper"

RSpec.describe CCU::Template::CsvTemplate do
  let(:release) { "8_3" }
  let(:generator) do
    Helpers::SetupGenerator.new(profile: profilename, rectypes: rectypes,
      release: release)
  end
  let(:profilename) { "core" }
  let(:rectypes) { %w[collectionobject] }
  let(:profile) { generator.profile }
  let(:rectype) { generator.rectype }
  let(:type) { "displayname" }
  let(:format) { :csvimporter }
  let(:template) { generator.template_object(type, format) }

  context "anthro profile" do
    let(:profilename) { "anthro" }

    context "object record type" do
      describe ".csvdata" do
        it "does not output computedCurrentLocation field" do
          headers = template.csvdata[6]
          result = headers.select do |h|
            h.start_with?("computedCurrentLocation")
          end
          expect(result).to be_empty
        end

        context "with datatoolkit format" do
          let(:format) { :datatoolkit }

          it "outputs single auth-controlled field with paired vocab field" do
            headers = template.csvdata[7]
            expect(headers).not_to include("anthroOwnerPersonLocal")
            expect(headers).not_to include("anthroOwnerOrganizationLocal")
            expect(headers).to include("anthroOwner")
            expect(headers).to include("anthroOwnerAuthorityVocabulary")
          end
        end
      end
    end

    context "movement record type" do
      let(:rectypes) { %w[movement] }

      describe ".csvdata" do
        it "correctly reports faux-requiredness" do
          headers = template.csvdata[7]
          req = template.csvdata[1]
          field_index = headers.index("movementReferenceNumber")
          expect(req[field_index]).to eq("y")
        end
      end
    end

    context "media record type" do
      let(:rectypes) { %w[media] }

      describe ".csvdata" do
        it "mediaFileURI column added" do
          headers = template.csvdata[7]
          expect(headers).to include("mediaFileURI")
        end
      end
    end

    context "restrictedmedia record type" do
      let(:release) { "8_2" }
      let(:rectypes) { %w[restrictedmedia] }

      describe ".csvdata" do
        it "mediaFileURI column added" do
          headers = template.csvdata[7]
          expect(headers).to include("mediaFileURI")
        end
      end
    end
  end
end
