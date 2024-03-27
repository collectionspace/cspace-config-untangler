# frozen_string_literal: true

require "spec_helper"

RSpec.describe CCU::Fields::Field do
  before do
    CCU.config.configdir = "spec/fixtures/files/6_0"
  end

  let(:core_profile) {
    CCU::Profile.new("core", rectypes: ["collectionobject"])
  }
  let(:co_fields) { core_profile.fields }
  let(:contentConcept) {
    co_fields.find { |f|
      f.name == "contentConcept"
    }
  }
  #  let(:anthro_profile) { CCU::Profile.new('anthro') }
  #  let(:anthro_co) { CCU::RecordType.new(anthro_profile, 'collectionobject') }
  #  let(:anthro_default) { anthro_co.forms['default'] }

  describe CCU::Fields::Field do
    describe "#value_source" do
      # tested in field_definition_spec
      # this just copies from the field_definition
      it "blah" do
        puts CCU.configdir
      end
    end
  end
end # RSpec
