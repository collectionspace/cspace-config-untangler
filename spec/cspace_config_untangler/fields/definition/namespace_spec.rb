# frozen_string_literal: true

require "spec_helper"

RSpec.describe CCU::Fields::Def::Namespace do
  let(:ns) { CCU::Fields::Def::Namespace.new(str, hash) }
  let(:str) { "ns2:collectionobjects_common" }
  let(:hash) { nil }

  describe "#literal" do
    let(:result) { ns.literal }

    it "returns literal namespace from rectype/fields/document config" do
      expect(result).to eq(str)
    end
  end

  describe "#for_id" do
    let(:result) { ns.for_id }

    it "returns literal namespace when no alternate provided" do
      expect(result).to eq(str)
    end

    context "when literal lookup namespace" do
      let(:str) { "ns2:propagations_common" }

      it "returns adjusted namespace" do
        expect(result).to eq("ns2:propagation_common")
      end
    end

    context "when extensionName lookup namespace" do
      let(:str) { "ns2:chronologies_common" }
      let(:hash) do
        {"[config]" => {
          "view" => {"type" => "CompoundInput"},
          "extensionName" => "associatedAuthority",
          "extensionParentConfig" => {
            "service" => {
              "ns" => "http://collectionspace.org/services/chronology"
            }
          }
        }}
      end

      it "returns adjusted namespace" do
        expect(result).to eq("ext.associatedAuthority")
      end
    end

    context "when message name lookup namespace" do
      let(:str) { "ns2:chronologies_common" }
      let(:hash) do
        {"[config]" =>
         {"messages" =>
          {"fullName" => {
             "id" => "field.ext.associatedAuthority.assocPerson.fullName",
             "defaultMessage" => "Associated person"
           },
           "name" => {
             "id" => "field.ext.associatedAuthority.assocPerson.name",
             "defaultMessage" => "Person"
           }},
          "view" => {
            "type" => "AutocompleteInput",
            "props" => {"source" => "person/local,person/ulan"}
          }}}
      end

      it "returns adjusted namespace" do
        expect(result).to eq("ext.associatedAuthority")
      end
    end
  end
end
