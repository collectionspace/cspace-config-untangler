# frozen_string_literal: true

require "spec_helper"
if CCU.lyrasis_staff
  RSpec.describe CCU::ClientBuilder do
    before(:each) { CCU.config.disable_api_checks = false }
    subject(:builder) { described_class.call(basename) }

    context "when community supported" do
      let(:basename) { "core" }

      it "returns client" do
        expect(builder.config.base_uri).to eq(
          "https://core.collectionspace.org/cspace-services"
        )
      end

      context "with dev instance env" do
        before { CCU.config.instance_env = :dev }

        it "returns client" do
          expect(builder.config.base_uri).to eq(
            "https://core.dev.collectionspace.org/cspace-services"
          )
        end
      end
    end

    context "when not community supported or configured" do
      let(:basename) { "foo" }

      it "raises Runtime Error" do
        expect { builder }.to raise_error(RuntimeError).with_message(
          "foo profile not configured for services API connection"
        )
      end
    end

    context "when configured with overrides" do
      before do
        CCU.config.community_supported_profiles = []
        path = File.join(Bundler.root, "spec", "fixtures", "files",
          "config.yml")
        cfg = <<~YAML
          anthro:
            base_uri: "https://anthro.dev.collectionspace.org/cspace-services"
            username: "reader@anthro.collectionspace.org"
            password: "reader"
        YAML
        File.open(path, "w") { |file| file << cfg }
        CCU.config.client_connection_config_path = path
      end
      after { File.delete(CCU.client_connection_config_path) }
      let(:basename) { "anthro" }

      it "returns client" do
        expect(builder.config.base_uri).to eq(
          "https://anthro.dev.collectionspace.org/cspace-services"
        )
      end
    end

    context "when client URL wrong" do
      before do
        CCU.config.community_supported_profiles = []
        path = File.join(Bundler.root, "spec", "fixtures", "files",
          "config.yml")
        cfg = <<~YAML
          anthro:
            base_uri: "https://antro.collectionspace.org/cspace-services"
            username: reader@anthro.collectionspace.org
            password: reader
        YAML
        File.open(path, "w") { |file| file << cfg }
        CCU.config.client_connection_config_path = path
      end
      after { File.delete(CCU.client_connection_config_path) }
      let(:basename) { "anthro" }

      it "raises Runtime Error" do
        expect { builder }.to raise_error(RuntimeError).with_message(
          "CollectionSpace::Client cannot connect. Check base_uri."
        )
      end
    end

    context "when client user has no access" do
      before do
        CCU.config.community_supported_profiles = []
        path = File.join(Bundler.root, "spec", "fixtures", "files",
          "config.yml")
        cfg = <<~YAML
          anthro:
            base_uri: "https://anthro.collectionspace.org/cspace-services"
            username: nope
            password: notreader
        YAML
        File.open(path, "w") { |file| file << cfg }
        CCU.config.client_connection_config_path = path
      end
      after { File.delete(CCU.client_connection_config_path) }
      let(:basename) { "anthro" }

      it "raises Runtime Error" do
        expect { builder }.to raise_error(RuntimeError).with_message(
          "CollectionSpace::Client user does not have permission to "\
            "access read-only information in instance. Check credentials."
        )
      end
    end
  end
end
