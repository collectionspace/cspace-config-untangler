# frozen_string_literal: true

require "spec_helper"

RSpec.describe CCU::FieldDefs::ExtractionManager do
  subject(:manager) { described_class.new(generator.rectype, field_config) }

  let(:profile) { "core" }
  let(:rectypes) { ["collectionobject"] }
  let(:field_config) do
    {
      "ns2:collectionspace_core" => {},
      "ns1" => {},
      "ns2" => {},
      "[config]" => {"view" => {"props" => {
        "defaultChildSubpath" => "fake namespace"
      }}}
    }
  end
  let(:generator) do
    Helpers::SetupGenerator.new(profile: profile, rectypes: rectypes)
  end

  describe "#ns" do
    it "sets as expected" do
      expect(manager.ns).to eq("fake namespace")
    end
  end

  describe "#call" do
    it "calls iterator as expected" do
      iterator = instance_double("Iterator", manager: manager)
      manager.instance_variable_set(:@iterator, iterator)
      expect(iterator).to receive(:call).with({name: "ns1", config: {},
mode: :namespace})
      expect(iterator).to receive(:call).with({name: "ns2", config: {},
mode: :namespace})
      manager.call
    end
  end
end
