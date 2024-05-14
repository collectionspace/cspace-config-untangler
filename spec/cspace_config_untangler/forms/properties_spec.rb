# frozen_string_literal: true

# # frozen_string_literal: true

# require "spec_helper"

# RSpec.describe CCU::Forms::Properties do
#   let(:release) { "8_0" }
#   let(:profilename) { "anthro" }
#   let(:rectypes) { ["collectionobject"] }
#   let(:generator) {
#     Helpers::SetupGenerator.new(profile: profilename, rectypes: rectypes,
#       release: release)
#   }
#   let(:form) { generator.form }
#   let(:formconfig) { form.instance_variable_get(:@config) }
#   let(:props) { CCU::Forms::Properties.new(form, fieldhash) }

# describe ".ns" do
#   context "with child of panel that is an extension" do
#     let(:fieldhash) { formconfig["children"][10]["props"] }
#     it "returns correct ns" do
#       field_props = props
#       child_hash = fieldhash["children"]["props"]
#       child_props = CCU::Forms::Properties.new(form, child_hash, field_props)
#       expect(child_props.ns).to eq("ns2:collectionobjects_anthro")
#     end
#   end
#   end
# end
