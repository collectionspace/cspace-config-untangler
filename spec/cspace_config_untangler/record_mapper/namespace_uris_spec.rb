# frozen_string_literal: true

require "spec_helper"

RSpec.describe CCU::RecordMapper::NamespaceUris do
  let(:generator) {
    Helpers::SetupGenerator.new(profile: profilename, rectypes: rectypes,
      release: release)
  }
  let(:profilename) { "core" }
  let(:release) { "6_1" }
  let(:nsuri) {
    CCU::RecordMapper::NamespaceUris.new(profile_config: profile.config,
      rectype: rectype, mapper_config: config)
  }
  let(:profile) { generator.profile }
  let(:rectype) { generator.rectype.name }
  let(:mapper) { generator.record_mapping }
  let(:config) { mapper.hash[:config] }

  describe NamespaceUris do
    let(:result) { nsuri.hash }

    context "when anthro profile" do
      let(:profilename) { "anthro" }

      context "when collectionobject rectype" do
        let(:rectypes) { ["collectionobject"] }
        let(:expected) do
          {
            "collectionobjects_common" => "http://collectionspace.org/services/collectionobject",
            "collectionobjects_culturalcare" => "http://collectionspace.org/services/collectionobject/domain/collectionobject",
            "collectionobjects_annotation" => "http://collectionspace.org/services/collectionobject/domain/annotation",
            "collectionobjects_nagpra" => "http://collectionspace.org/services/collectionobject/domain/nagpra",
            "collectionobjects_anthro" => "http://collectionspace.org/services/collectionobject/domain/anthro",
            "collectionobjects_naturalhistory_extension" => "http://collectionspace.org/services/collectionobject/domain/naturalhistory_extension"
          }
        end

        it "generates hash correctly" do
          expected.keys.each { |k| expect(result[k]).to eq(expected[k]) }
        end
      end

      context "when claim rectype" do
        let(:rectypes) { ["claim"] }
        let(:expected) do
          {
            "claims_nagpra" => "http://collectionspace.org/services/claim/domain/nagpra",
            "claims_common" => "http://collectionspace.org/services/claim"
          }
        end

        it "generates hash correctly" do
          expected.keys.each { |k| expect(result[k]).to eq(expected[k]) }
        end
      end

      context "when place rectype" do
        let(:rectypes) { ["place"] }
        let(:expected) do
          {
            "places_common" => "http://collectionspace.org/services/place"
          }
        end

        it "generates hash correctly" do
          expected.keys.each { |k| expect(result[k]).to eq(expected[k]) }
        end
      end

      context "when taxon rectype" do
        let(:rectypes) { ["taxon"] }
        let(:expected) do
          {
            "taxon_common" => "http://collectionspace.org/services/taxonomy"
          }
        end

        it "generates hash correctly" do
          expected.keys.each { |k| expect(result[k]).to eq(expected[k]) }
        end
      end
    end
  end
end
