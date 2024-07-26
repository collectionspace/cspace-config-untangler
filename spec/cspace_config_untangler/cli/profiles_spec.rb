# frozen_string_literal: true

require "spec_helper"

RSpec.describe CCU::Cli::Profiles do
  before(:each) do
    delete_all_configs
    set_profile_release("7_0")
  end

  after(:each) { CCU.reset_config }

  describe "#all" do
    it "prints all known profiles to screen" do
      allow(subject.shell).to receive(:say)
      msg = "anthro_5-0-0\nbonsai_5-0-0\nbotgarden_3-0-0\ncore_7-0-0\n"\
        "fcart_4-0-0\nherbarium_2-0-0\nlhmc_4-0-0\nmaterials_3-0-0\n"\
        "publicart_3-0-0"
      subject.invoke(:all, [], {})
      expect(subject.shell).to have_received(:say).with(msg).once
    end
  end

  describe "#check" do
    it "prints given profiles to screen" do
      allow(subject.shell).to receive(:say)
      msg = "core_7-0-0\nbonsai_5-0-0"
      subject.invoke(:check, [],
        {"profiles" => "core_7-0-0,bonsai_5-0-0"})
      expect(subject.shell).to have_received(:say).with(msg).once
    end
  end

  describe "#compare" do
    let(:outfile) { "#{fixtures}/compare_core_7-0-0_to_bonsai_5-0-0.csv" }
    let(:result) { subject.invoke(:compare, [], opts) }

    context "with expected parameters" do
      after(:each) do
        File.delete("#{fixtures}/compare_core_7-0-0_to_bonsai_5-0-0.csv")
      end
      let(:opts) do
        {"profiles" => "core_7-0-0,bonsai_5-0-0", "output_dir" => fixtures}
      end
      let(:msg) do
        <<~MSG
          not in core_7-0-0: 89
          not in bonsai_5-0-0: 55
          source differences: 3
          ui path differences: 0
          same: 769

          Wrote detailed report to: #{outfile}
        MSG
      end

      it "writes csv file to given output directory" do
        allow(subject.shell).to receive(:say)
        result
        expect(subject.shell).to have_received(:say).with(msg.chomp).once
        expect(File.exist?(outfile)).to be true
      end
    end

    context "with more than two profiles specified" do
      let(:opts) { {"profiles" => "all", "output" => fixtures} }
      let(:msg) { "Can only compare two profiles at a time" }
      it "returns warning message" do
        allow(subject.shell).to receive(:say)
        expect(subject.shell).to receive(:say).with(msg.chomp).once
        expect { result }.to raise_error(SystemExit)
      end
    end

    context "with only one profile specified" do
      let(:opts) { {"profiles" => "core_7-0-0", "output" => fixtures} }
      let(:msg) { "Needs two profiles to compare" }
      it "returns warning message" do
        allow(subject.shell).to receive(:say)
        expect(subject.shell).to receive(:say).with(msg.chomp).once
        expect { result }.to raise_error(SystemExit)
      end
    end
  end

  describe "#by_extension" do
    let(:opts) { {"profiles" => "core_7-0-0,anthro_5-0-0"} }
    let(:msg) do
      address
      anthro_5
      core_7
      blob
      anthro_5
      core_7
      contact
      anthro_5
      core_7
      culturalcare
      anthro_5
      dimension
      anthro_5
      core_7
      locality
      anthro_5
      nagpra
      anthro_5
      naturalhistory
      anthro_5
      structuredDate
      anthro_5
      core_7
      it "prints profiles by extension report to screen" do
        allow(subject.shell).to receive(:say)
        subject.invoke(:by_extension, [], opts)
        expect(subject.shell).to have_received(:say).with(msg.chomp).once
      end
    end
  end

  describe "#main" do
    it "prints name of main profile to screen" do
      allow(subject.shell).to receive(:say)
      subject.invoke(:main, [], {})
      expect(subject.shell).to have_received(:say).with("core_7-0-0").once
    end
  end

  describe "#readable" do
    before(:each) do
      @testprofile = "test_1-1-1"
      origstr = '{"allowDeleteHierarchyLeaves":false,"autocompleteFindDelay"'\
        ':500,"autocompleteMinLength":3,"basename":"/cspace/profile",'\
        '"className":"cspace-ui-plugin-profile-profile--common","container":'\
        '"#cspace","defaultAdvancedSearchBooleanOp":"and",'\
        '"defaultDropdownFilter":"substring","defaultUserPrefs":{"panels":{'\
        '"collectionobject":{"mediaSnapshotPanel":{"collapsed":false}}}},'\
        '"index":"/search","locale":"en-US"}'
      @profilepath = "#{CCU.configdir}/#{@testprofile}.json"
      File.write(@profilepath, origstr)
    end

    after(:each) { File.delete(@profilepath) }

    it "reformats profiles" do
      allow(subject.shell).to receive(:say)
      subject.invoke(:readable, [], {"profiles" => @testprofile})
      newstr = File.read(@profilepath)
      expected = <<~EXP
        {
          "allowDeleteHierarchyLeaves": false,
          "autocompleteFindDelay": 500,
          "autocompleteMinLength": 3,
          "basename": "/cspace/profile",
          "className": "cspace-ui-plugin-profile-profile--common",
          "container": "#cspace",
          "defaultAdvancedSearchBooleanOp": "and",
          "defaultDropdownFilter": "substring",
          "defaultUserPrefs": {
            "panels": {
              "collectionobject": {
                "mediaSnapshotPanel": {
                  "collapsed": false
                }
              }
            }
          },
          "index": "/search",
          "locale": "en-US"
        }
      EXP
      msg = "Reformatting #{@testprofile} config"
      expect(subject.shell).to have_received(:say).with(msg).once
      expect(newstr).to eq(expected)
    end
  end
end
