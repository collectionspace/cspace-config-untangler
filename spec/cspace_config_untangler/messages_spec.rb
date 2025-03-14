# frozen_string_literal: true

require "spec_helper"

RSpec.describe CCU::Messages, :aggregate_failures do
  subject(:messages) { described_class.new }

  describe "#add" do
    context "with complex config" do
      it "adds as expected" do
        config = {"record" => {
                    "name" => {"id" => "record.contact.name",
                               "defaultMessage" => "Contact"},
                    "collectionName" => {
                      "id" => "record.contact.collectionName",
                      "defaultMessage" => "Contacts"
                    }
                  },
                  "panel" => {
                    "info" => {"id" => "panel.contact.info",
                               "defaultMessage" => "Contact Information"}
                  }}
        messages.add(config)
        expect(messages.size).to eq(3)
      end
    end

    context "with simple config" do
      it "adds as expected" do
        config = {"id" => "record.contact.name",
                  "defaultMessage" => "Contact"}
        messages.add(config)
        expect(messages.size).to eq(1)
      end
    end
  end
end
