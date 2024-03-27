require "spec_helper"

RSpec.describe CCU::Fields::ValueSources::TypeExtractor do
  let(:extractor) { CCU::Fields::ValueSources::TypeExtractor }

  describe "#call" do
    let(:result) { extractor.call(hash) }

    context "with AutocompleteInput" do
      let(:hash) do
        {"messages" =>
         {"name" =>
          {"id" => "field.collectionobjects_common.namedCollection.name",
           "defaultMessage" => "Named collection"}},
         "repeating" => true,
         "view" => {"type" => "AutocompleteInput",
                    "props" => {"source" => "work/local"}}}
      end
      it "returns authority" do
        expect(result).to eq("authority")
      end
    end

    context "with OptionPickerInput" do
      let(:hash) do
        {"messages" =>
         {"fullName" =>
          {"id" => "field.collectionobjects_common.numberType.fullName",
           "defaultMessage" => "Other number type"},
          "name" => {"id" => "field.collectionobjects_common.numberType.name",
                     "defaultMessage" => "Type"}},
         "view" => {"type" => "OptionPickerInput",
                    "props" => {"source" => "numberTypes"}}}
      end
      it "returns option list" do
        expect(result).to eq("option list")
      end
    end

    context "with TermPickerInput" do
      let(:hash) do
        {"defaultValue" =>
         "urn:cspace:core.collectionspace.org:vocabularies:name(publishto):item:name(none)'None'",
         "messages" =>
         {"name" =>
          {"id" => "field.collectionobjects_common.publishTo.name",
           "defaultMessage" => "Publish to"}},
         "repeating" => true,
         "view" => {"type" => "TermPickerInput",
                    "props" => {"source" => "publishto"}}}
      end
      it "returns vocabulary" do
        expect(result).to eq("vocabulary")
      end
    end

    context "with IDGeneratorInput" do
      let(:hash) do
        {"cloneable" => false,
         "messages" =>
           {"name" =>
            {"id" => "field.collectionobjects_common.objectNumber.name",
             "defaultMessage" => "Identification number"}},
         "required" => true,
         "searchView" => {"type" => "TextInput"},
         "view" => {"type" => "IDGeneratorInput",
                    "props" => {"source" => "accession,intake,loanin"}}}
      end
      it "returns nil" do
        expect(result).to eq("no source")
      end
    end

    context "with no view data" do
      let(:hash) { {} }
      it "returns nil" do
        expect(result).to eq("no source")
      end
    end
  end
end
