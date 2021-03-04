require 'spec_helper'

RSpec.describe CCU::RecordType do

  before(:all) do
    CCU.const_set('CONFIGDIR', 'spec/fixtures/files/6_0')
    @core_profile = CCU::Profile.new(profile: 'core', rectypes: %w[collectionobject media person])
    @anthro_profile = CCU::Profile.new(profile: 'anthro', rectypes: %w[collectionobject movement media])
    @bg_profile = CCU::Profile.new(profile: 'botgarden', rectypes: %w[collectionobject])
    @core_co = @core_profile.rectypes[0]
    @core_media = @core_profile.rectypes[1]
    @core_person = @core_profile.rectypes[2]
    @anthro_co = @anthro_profile.rectypes[0]
    @anthro_movement = @anthro_profile.rectypes[1]
    @anthro_media = @anthro_profile.rectypes[2]
    @bg_co = @bg_profile.rectypes[0]
  end
  describe '.new' do
    it 'creates CCU::RecordType object' do
      expect(@core_co).to be_instance_of(CCU::RecordType)
    end

    it 'sets service_type attribute as expected' do
      result = [@core_co, @core_media, @core_person].map{ |rt| rt.service_type }
      expect(result).to eq(['object', 'procedure', 'authority'])
    end

    context 'when service_type = authority' do
      it 'sets subtypes attribute as expected' do
        result = @core_person.subtypes
        expected = [
          {
            name: 'Local',
            subtype: 'person'
          },
          {
            name: 'ULAN',
            subtype: 'ulan_pa'
          }
        ]
        expect(result).to eq(expected)
      end
    end

    context 'when service_type = object or procedure' do
      it 'subtypes attribute is empty array' do
        result = [@core_co, @core_media].map{ |rt| rt.subtypes }
        expect(result).to eq([[], []])
      end
    end
  end

  describe '.id_field' do
    context 'when anthro profile' do
      context 'when movement rectype' do
        it 'returns movementReferenceNumber' do
          expect(@anthro_movement.id_field).to eq('movementReferenceNumber')
        end
      end
    end
  end
  
  describe '.panels' do
    it 'returns array' do
      expect(@anthro_co.panels).to be_instance_of(Array)
    end
    it 'includes all panel names for rectype' do
      p = ['id', 'desc', 'content', 'textInscript', 'nonTextInscript', 'prod', 'hist', 'assoc', 'owner',
           'viewer', 'reference', 'collect', 'hierarchy', 'bio', 'commingledRemains', 'locality',
           'culturalCare', 'georefDetail', 'nagpraCompliance'].sort
      expect(@anthro_co.panels.sort).to eq(p)
    end
  end

  describe '.input_tables' do
    it 'returns hash' do
      expect(@anthro_co.input_tables).to be_instance_of(Hash)
    end
    it 'keys are the panel names for rectype' do
      p = ['age', 'assocEvent', 'ownershipExchange', 'behrensmeyer', 'depth', 'elevation',
           'distanceAboveSurface', 'nagpraReportFiled', 'taxonName', 'taxonIdent', 'taxonReference'].sort
      expect(@anthro_co.input_tables.keys.sort).to eq(p)
    end
  end

  describe '.forms' do
    it 'returns hash' do
      expect(@anthro_co.forms).to be_instance_of(Hash)
    end
    it 'hash keys are the form names' do
      a = %w[default inventory photo].sort
      expect(@anthro_co.forms.keys.sort).to eq(a)
    end
    
    it 'hash values are CCU::Form objects' do
      expect(@anthro_co.forms['default']).to be_instance_of(CCU::Form)
    end
  end

  describe '.mappings' do
    context 'anthro profile' do
      context 'collectionobject recordtype' do
        before(:all) do
          @mappings = @anthro_co.mappings
        end
        context 'fieldname = sex' do
          it 'columnnames: sex, commingledRemainsGroup_sex' do
            result = @mappings.select{ |m| m.fieldname == 'sex' }.map{ |m| m.datacolumn }.sort
            expect(result).to eq(%w[commingledRemainsGroup_sex sex])
          end
        end
        context 'fieldname = reference' do
          # does NOT change datacolumn values, as one field's use of multiple authorities
          #  has already caused all datacolumn values to be different
          it 'columnnames: reference referenceLocal referenceWorldcat' do
            result = @mappings.select{ |m| m.fieldname == 'reference' }.map{ |m| m.datacolumn }.sort
            expect(result).to eq(%w[reference referenceLocal referenceRefname referenceWorldcat])
          end
        end
        context 'fieldname = fieldLocVerbatim' do
          it 'columnnames: fieldLocVerbatim localityGroup_fieldLocVerbatim' do
            result = @mappings.select{ |m| m.fieldname == 'fieldLocVerbatim' }.map{ |m| m.datacolumn }.sort
            expect(result).to eq(%w[fieldLocVerbatim localityGroup_fieldLocVerbatim])
          end
        end
      end
      context 'when movement recordtype' do
        before(:all) do
          @mappings = @anthro_movement.mappings
        end
        context 'with fieldname = movementReferenceNumber' do
          it 'is not required' do
            result = @mappings.select{ |m| m.fieldname == 'movementReferenceNumber' }.map{ |m| m.required }.sort
            expect(result).to eq(%w[n])
          end
        end
      end
    end
  end

  describe '.fields' do
    context 'core profile' do
      context 'media recordtype' do
        before(:all) do
          @fields = @core_media.fields
        end
        it 'includes mediaFileURI field' do
          result = @fields.select{ |f| f.name == 'mediaFileURI' }
          expect(result.length).to eq(1)
        end
      end
    end
  end

    describe '.batch_mappings' do
    context 'anthro profile' do
      context 'collectionobject recordtype' do
        before(:all) do
          @mappings = @anthro_co.batch_mappings
        end
        it 'removes computedCurrentLocation mappings' do
          result = @mappings.select{ |m| m.fieldname == 'computedCurrentLocation' }
          expect(result).to be_empty
        end
      end
      context 'media recordtype' do
        before(:all) do
          @mappings = @anthro_media.batch_mappings
        end
        it 'removes mediaFileURI mappings' do
          result = @mappings.select{ |m| m.fieldname == 'mediaFileURI' }
          expect(result).to be_empty
        end
      end
      context 'movement recordtype' do
        before(:all) do
          @mappings = @anthro_movement.batch_mappings
        end
        context 'fieldname = movementReferenceNumber' do
          it 'is required' do
            result = @mappings.select{ |m| m.fieldname == 'movementReferenceNumber' }.map{ |m| m.required }.sort
            expect(result).to eq(%w[y])
          end
        end
      end
    end
  end
end #RSpec
