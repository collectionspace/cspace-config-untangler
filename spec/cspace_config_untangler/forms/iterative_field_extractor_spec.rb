# # frozen_string_literal: true

# require 'spec_helper'

# RSpec.describe CCU::Forms::IterativeFieldExtractor do
#   subject(:iterator) { described_class.new(form, fieldhash, parent) }

#   let(:release) { '8_0' }
#   let(:profilename) { 'anthro' }
#   let(:rectypes) { ['collectionobject'] }
#   let(:generator) do
#     Helpers::SetupGenerator.new(profile: profilename, rectypes:,
#                                 release:)
#   end
#   let(:form) { generator.form }
#   let(:formconfig) { form.field_config }
#   let(:parent) { nil }

#   describe 'subrecord' do
#     context 'when prop represents a form panel' do
#       let(:rectypes) { ['organization'] }
#       let(:fieldhash) do
#
#       end

#       it 'returns true' do
#         expect(iterator.call).to eq(true)
#       end
#     end
#   end
# end
