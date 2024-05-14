# frozen_string_literal: true

require "spec_helper"

RSpec.describe CCU::Fields::Field do
  before do
    CCU.config.configdir = "spec/fixtures/files/6_0"
  end

  let(:core_profile) do
    CCU::Profile.new("core", rectypes: ["collectionobject"])
  end
  let(:co_fields) { core_profile.fields }
  let(:contentConcept) do
    co_fields.find do |f|
      f.name == "contentConcept"
    end
  end
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
