# frozen_string_literal: true

require "spec_helper"

RSpec.describe CCU::Fields::Def::NamespaceFieldParser do
  let(:generator) do
    Helpers::SetupGenerator.new(profile: "core", rectypes: ["person"])
  end
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
