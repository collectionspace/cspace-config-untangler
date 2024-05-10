# frozen_string_literal: true

require "spec_helper"

RSpec.describe CCU::Template::CsvTemplate do
  let(:release) { "7_0" }
  let(:generator) do
    Helpers::SetupGenerator.new(profile: profilename, rectypes: rectypes,
      release: release)
  end
  let(:profilename) { "anthro" }
  let(:rectypes) { %w[collectionobject] }
  let(:profile) { generator.profile }
  let(:rectype) { generator.rectype }
  let(:type) { "displayname" }
  let(:template_o) { generator.template_testable(type) }
  let(:template_f) { generator.template_file }

  context "anthro profile" do
    context "object record type" do
      it "generates expected csvdata" do
        expect(template_o.length).to eq(template_f.length)
        template_o.each_with_index do |fielddata, i|
          expect(fielddata).to eq(template_f[i])
        end
      end
    end
  end
end
