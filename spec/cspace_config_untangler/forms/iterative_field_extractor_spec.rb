# frozen_string_literal: true

require "spec_helper"

RSpec.describe CCU::Forms::IterativeFieldExtractor do
  subject(:iterator) { described_class.new(form, fieldhash, parent) }

  let(:release) { "8_0" }
  let(:profilename) { "anthro" }
  let(:rectypes) { ["collectionobject"] }
  let(:generator) {
    Helpers::SetupGenerator.new(profile: profilename, rectypes: rectypes,
      release: release)
  }
  let(:form) { generator.form }
  let(:formconfig) { form.field_config }
  let(:parent) { nil }

  # describe ".is_panel" do
  #   context "when prop represents a form panel" do
  #     let(:fieldhash) { formconfig["children"][0]["props"] }
  #     it "returns true" do
  #       expect(iterator.is_panel).to eq(true)
  #     end
  #   end
  #   context "when prop does not represent a form panel" do
  #     let(:fieldhash) {
  #       formconfig["children"][0]["props"]["children"][0]["props"]
  #     }
  #     it "returns false" do
  #       expect(props.is_panel).to eq(false)
  #     end
  #   end
  # end
end
