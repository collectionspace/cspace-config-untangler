require 'spec_helper'

RSpec.describe CCU::RecordMapper do
  before(:all) do
    CCU.const_set('CONFIGDIR', 'spec/fixtures/files/6_1')
  end

  context 'botgarden' do
    before(:all) do
      @profile = CCU::Profile.new(profile: 'botgarden_2-0-1',
                                  rectypes: ['loanout'],
                                  structured_date_treatment: :collapse)
    end
    context 'loanout' do
      before(:all) do
        @loanout = @profile.rectypes.select{ |rt| rt.name == 'loanout' }.first
        @mapper = RecordMapping.new(profile: @profile, rectype: @loanout)
        @config = @mapper.hash[:config]
      end
      describe RecordMapping do
        describe '#hash[:config]' do
          it "hash[:config][:service_type'] = 'procedure'" do
            expect(@config[:service_type]).to eq('procedure')
          end
          it "hash[:config][:identifier_field'] = 'loanOutNumber'" do
            expect(@config[:identifier_field]).to eq('loanOutNumber')
          end
        end
      end
    end
  end

  context 'anthro' do
    before(:all) do
      @anthro_profile = CCU::Profile.new(profile: 'anthro_4-1-0',
                                         rectypes: ['collectionobject', 'claim',
                                                    'osteology', 'place', 'taxon'],
                                         structured_date_treatment: :collapse)
    end
    context 'collectionobject' do
      before(:all) do
        @anthro_co = @anthro_profile.rectypes.select{ |rt| rt.name == 'collectionobject' }.first
        @rm_anthro_co = RecordMapping.new(profile: @anthro_profile, rectype: @anthro_co)
        @co_config = @rm_anthro_co.hash[:config]
      end
      describe RecordMapping do
        describe '#hash[:config]' do
          it "hash[:config][:service_type'] = 'object'" do
            expect(@co_config[:service_type]).to eq('object')
          end
          it "hash[:config][:identifier_field'] = 'objectNumber'" do
            expect(@co_config[:identifier_field]).to eq('objectNumber')
          end
        end
      end
      describe NamespaceUris do
        let(:result) { NamespaceUris.new(profile_config: @anthro_profile.config,
                                         rectype: 'collectionobject',
                                         mapper_config: @co_config
                                        ).hash }

        let(:expected) { {
          'collectionobjects_common' => 'http://collectionspace.org/services/collectionobject',
          'collectionobjects_culturalcare' => 'http://collectionspace.org/services/collectionobject/domain/collectionobject',
          'collectionobjects_annotation' => 'http://collectionspace.org/services/collectionobject/domain/annotation',
          'collectionobjects_nagpra' => 'http://collectionspace.org/services/collectionobject/domain/nagpra',
          'collectionobjects_anthro' => 'http://collectionspace.org/services/collectionobject/domain/anthro',
          'collectionobjects_naturalhistory_extension' => 'http://collectionspace.org/services/collectionobject/domain/naturalhistory_extension'
        } }

        it 'generates hash correctly' do
          expected.keys.each{ |k| expect(result[k]).to eq(expected[k]) }
        end
      end
    end

    context 'claim' do
      before(:all) do
        @anthro_claim = @anthro_profile.rectypes.select{ |rt| rt.name == 'claim' }.first
        @rm_anthro_claim = RecordMapping.new(profile: @anthro_profile, rectype: @anthro_claim)
        @claim_config = @rm_anthro_claim.hash[:config]
      end
      describe RecordMapping do
        describe '#hash[:config]' do
          it "hash[:config][:service_type'] = 'procedure'" do
            expect(@claim_config[:service_type]).to eq('procedure')
          end
          it "hash[:config][:identifier_field'] = 'claimNumber'" do
            expect(@claim_config[:identifier_field]).to eq('claimNumber')
          end
        end
      end
      describe NamespaceUris do
        let(:result) { NamespaceUris.new(profile_config: @anthro_profile.config,
                                         rectype: 'claim',
                                         mapper_config: @claim_config
                                        ).hash }

        let(:expected) { {
          'claims_nagpra' => 'http://collectionspace.org/services/claim/domain/nagpra',
          'claims_common' => 'http://collectionspace.org/services/claim'
        } }

        it 'generates hash correctly' do
          expected.keys.each{ |k| expect(result[k]).to eq(expected[k]) }
        end
      end
    end

    context 'osteology' do
      before(:all) do
        @anthro_ost = @anthro_profile.rectypes.select{ |rt| rt.name == 'osteology' }.first
        @rm_anthro_ost = RecordMapping.new(profile: @anthro_profile, rectype: @anthro_ost)
        @ost_config = @rm_anthro_ost.hash[:config]
      end
      describe RecordMapping do
        describe '#hash[:config]' do
          it "hash[:config][:service_type'] = 'procedure'" do
            expect(@ost_config[:service_type]).to eq('procedure')
          end
          it "hash[:config][:identifier_field'] = 'InventoryID'" do
            expect(@ost_config[:identifier_field]).to eq('InventoryID')
          end
        end
      end
    end
    
    context 'place' do
      before(:all) do
        @rectype = @anthro_profile.rectypes.select{ |rt| rt.name == 'place' }.first
        @mapper = RecordMapping.new(profile: @anthro_profile, rectype: @rectype)
        @config = @mapper.hash[:config]
      end
      describe NamespaceUris do
        let(:result) { NamespaceUris.new(profile_config: @anthro_profile.config,
                                         rectype: 'place',
                                         mapper_config: @config
                                        ).hash }
        let(:expected) { {
          'places_common' => 'http://collectionspace.org/services/place'
        } }

        it 'generates hash correctly' do
          expected.keys.each{ |k| expect(result[k]).to eq(expected[k]) }
        end
      end
    end

    context 'taxon' do
      before(:all) do
        @anthro_taxon = @anthro_profile.rectypes.select{ |rt| rt.name == 'taxon' }.first
        @rm_anthro_taxon = RecordMapping.new(profile: @anthro_profile, rectype: @anthro_taxon)
        @taxon_config = @rm_anthro_taxon.hash[:config]
      end
      describe RecordMapping do
        describe '#hash[:config]' do
          it "[:service_type] = 'authority'" do
            expect(@taxon_config[:service_type]).to eq('authority')
          end
          it "[:identifier_field] = 'shortIdentifier'" do
            expect(@taxon_config[:identifier_field]).to eq('shortIdentifier')
          end
          it '[:authority_subtypes] returns array of hashes with keys: name, servicepathname' do
            subtypes = @taxon_config[:authority_subtypes]
            expected = [
              { name: 'Local', subtype: 'taxon' },
              { name: 'Common', subtype: 'common_ta' }
            ]
            expect(subtypes).to eq(expected)
          end
        end
      end
      describe NamespaceUris do
        let(:result) { NamespaceUris.new(profile_config: @anthro_profile.config,
                                         rectype: 'taxon',
                                         mapper_config: @taxon_config
                                        ).hash }
        let(:expected) { {
          'taxon_common' => 'http://collectionspace.org/services/taxonomy'
        } }

        it 'generates hash correctly' do
          expected.keys.each{ |k| expect(result[k]).to eq(expected[k]) }
        end
      end
    end
  end
end #RSpec
