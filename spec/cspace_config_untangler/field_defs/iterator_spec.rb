# frozen_string_literal: true

require "spec_helper"

RSpec.describe CCU::FieldDefs::Iterator do
  subject(:iterator) { described_class.new(manager) }

  let(:manager) { instance_double("Iterator", rectype: generator.rectype) }
  let(:profile) { "core" }
  let(:rectypes) { ["collectionobject"] }
  # let(:field_config) do
  #   {
  #     "ns2:collectionspace_core" => {},
  #     "ns1" => {},
  #     "ns2" => {},
  #     "[config]" => {"view" => {"props" => {
  #       "defaultChildSubpath" => "fake namespace"
  #     }}}
  #   }
  # end
  let(:generator) do
    Helpers::SetupGenerator.new(profile: profile, rectypes: rectypes)
  end

  describe "#call" do
    it "calls iterator as expected" do
      iterator.call(name: "meh", config: {}, mode: :namespace)
    end
  end
end
