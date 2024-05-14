# frozen_string_literal: true

require "spec_helper"

RSpec.describe CCU::Template::CsvTemplate do
  let(:release) { "6_1" }
  let(:generator) do
    Helpers::SetupGenerator.new(profile: profilename, rectypes: rectypes,
      release: release)
  end
  let(:profilename) { "core" }
  let(:rectypes) { %w[collectionobject] }
  let(:profile) { generator.profile }
  let(:rectype) { generator.rectype }
  let(:type) { "displayname" }
  let(:template) { generator.template_object(type) }

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
  end
end
