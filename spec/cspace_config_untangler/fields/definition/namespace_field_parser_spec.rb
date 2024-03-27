require "spec_helper"

RSpec.describe CCU::Fields::Def::NamespaceFieldParser do
  let(:generator) {
    Helpers::SetupGenerator.new(profile: "core", rectypes: ["person"])
  }
  let(:ns) { "ns2:contacts_common" }
  let(:config) { generator.field_def_config(ns) }
  let(:parser) { generator.namespace_field_parser(ns, config) }

  context "when core/person/contacts" do
    it "gets extension config" do
      parser
      expect(config.hash.keys.any?("emailGroupList")).to be true
    end
  end
end
