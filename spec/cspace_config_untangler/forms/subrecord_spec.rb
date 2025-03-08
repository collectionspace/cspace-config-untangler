# frozen_string_literal: true

require "spec_helper"

RSpec.describe CCU::Forms::Subrecord, aggregate_failures: true do
  subject(:subrec) do
    iter = CCU::Forms::IterativeFieldExtractor.new(form, formconfig)
    iter.call
    props = iter.send(:allprops)
      .find { |p| p.config["name"] == name && !p.skippable? }
    CCU::Forms::Subrecord.new(name, form, CCU::Forms::PropsValidator.new, props)
  end

  let(:release) { "8_0" }
  let(:profilename) { "anthro" }
  let(:generator) do
    Helpers::SetupGenerator.new(
      profile: profilename,
      rectypes: rectypes,
      release: release
    )
  end
  let(:templatename) { "default" }
  let(:form) { generator.form(templatename) }
  let(:formconfig) { form.field_config }

  context "when contact" do
    let(:rectypes) { ["person"] }
    let(:name) { "contact" }

    it "behaves as expected" do
      expect(subrec.name).to eq("info")
      expect(subrec.ns).to eq("ns2:contacts_common")
      expect(subrec.is_panel).to be true
      expect(subrec.extension?).to be true
      expect(subrec.panel).to eq("panel.contact.info")
    end
  end

  context "when blob" do
    let(:rectypes) { ["media"] }
    let(:name) { "file" }

    it "behaves as expected" do
      expect(subrec.name).to eq("childHolder")
      expect(subrec.ns).to eq("ns2:blobs_common")
      expect(subrec.is_panel).to be true
      expect(subrec.extension?).to be true
      expect(subrec.panel).to be_nil
    end
  end
end
