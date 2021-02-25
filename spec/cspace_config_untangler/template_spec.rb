require 'spec_helper'

RSpec.describe CCU::Template::CsvTemplate do
  before(:all) do
    CCU.const_set('CONFIGDIR', 'spec/fixtures/files/6_1')
  end
  context 'anthro profile' do
    before(:all) do
      @anthro_profile = CCU::Profile.new(profile: 'anthro_4-1-0', rectypes: %w[collectionobject movement],
                                        structured_date_treatment: :collapse)
    end
    context 'object record type' do
      before(:all) do
        @anthro_object = @anthro_profile.rectypes[0]
        @anthro_object_template = CsvTemplate.new(profile: @anthro_profile, rectype: @anthro_object, type: 'displayname')
      end
      describe '.csvdata' do
        it 'does not output computedCurrentLocation field' do
          headers = @anthro_object_template.csvdata[6]
          result = headers.select{ |h| h.start_with?('computedCurrentLocation') }
          expect(result).to be_empty
        end
      end
    end
    context 'movement record type' do
      before(:all) do
        @anthro_movement = @anthro_profile.rectypes[1]
        @anthro_movement_template = CsvTemplate.new(profile: @anthro_profile, rectype: @anthro_movement, type: 'displayname')
      end
      describe '.csvdata' do
        it 'correctly reports faux-requiredness' do
          headers = @anthro_movement_template.csvdata[7]
          req = @anthro_movement_template.csvdata[1]
          field_index = headers.index('movementReferenceNumber')
          expect(req[field_index]).to eq('y')
        end
      end
    end
  end
end #RSpec
