require 'spec_helper'

RSpec.describe CCU::Cli::ProfilesCli do
  before(:context){ set_profile_release('7_0') }
  describe '#all' do
    it "prints all known profiles to screen" do
      allow(subject.shell).to receive(:say)
      msg = "anthro_5-0-0\nbonsai_5-0-0\nbotgarden_3-0-0\ncore_7-0-0\nfcart_4-0-0\nherbarium_2-0-0\nlhmc_4-0-0\nmaterials_3-0-0\npublicart_3-0-0"
      result = subject.invoke(:all, [], {})
      expect(subject.shell).to have_received(:say).with(msg).once
    end
  end

  describe '#check' do
    it "prints given profiles to screen" do
      allow(subject.shell).to receive(:say)
      msg = "core_7-0-0\nbonsai_5-0-0"
      result = subject.invoke(:check, [], {"profiles"=>"core_7-0-0,bonsai_5-0-0"})
      expect(subject.shell).to have_received(:say).with(msg).once
    end
  end

  describe '#compare' do
    let(:outfile){ "#{fixtures}/compare_core_7-0-0_to_bonsai_5-0-0.csv" }
    context 'with expected parameters' do
      after(:context){ File.delete("#{fixtures}/compare_core_7-0-0_to_bonsai_5-0-0.csv") }
      let(:opts){ {'profiles'=>'core_7-0-0,bonsai_5-0-0', 'output'=>fixtures} }
      let(:msg) do
        <<~MSG
        not in core_7-0-0: 89
        not in bonsai_5-0-0: 77
        source differences: 3
        ui path differences: 0
        same: 1300

        Wrote detailed report to: #{outfile}
        MSG
      end
      it "writes csv file to given output directory" do
        allow(subject.shell).to receive(:say)
        result = subject.invoke(:compare, [], opts)
        expect(subject.shell).to have_received(:say).with(msg.chomp).once
        expect(File.exist?(outfile)).to be true
      end
    end

    context 'with more than two profiles specified' do
      let(:opts){ {'profiles'=>'all', 'output'=>fixtures} }
      let(:msg){ 'Can only compare two profiles at a time' }
      it 'returns warning message' do
        allow(subject.shell).to receive(:say)
        result = subject.invoke(:compare, [], opts)
        expect(subject.shell).to have_received(:say).with(msg.chomp).once
        expect(File.exist?(outfile)).to be false
      end
    end

    context 'with only one profile specified' do
      let(:opts){ {'output'=>fixtures} }
      let(:msg){ 'Needs two profiles to compare' }
      it 'returns warning message' do
        allow(subject.shell).to receive(:say)
        result = subject.invoke(:compare, [], opts)
        expect(subject.shell).to have_received(:say).with(msg.chomp).once
        expect(File.exist?(outfile)).to be false
      end
    end
  end

  describe '#by_extension' do
    let(:opts){ {'profiles'=>'core_7-0-0,anthro_5-0-0'} }
    let(:msg) do
      <<~MSG
      address
        anthro_5-0-0
        core_7-0-0
      blob
        anthro_5-0-0
        core_7-0-0
      contact
        anthro_5-0-0
        core_7-0-0
      culturalcare
        anthro_5-0-0
      dimension
        anthro_5-0-0
        core_7-0-0
      locality
        anthro_5-0-0
      nagpra
        anthro_5-0-0
      naturalhistory
        anthro_5-0-0
      structuredDate
        anthro_5-0-0
        core_7-0-0
  MSG
      it "prints profiles by extension report to screen" do
        allow(subject.shell).to receive(:say)
        result = subject.invoke(:by_extension, [], opts)
        expect(subject.shell).to have_received(:say).with(msg.chomp).once
      end
    end
  end

  describe '#main' do
    it "prints name of main profile to screen" do
      allow(subject.shell).to receive(:say)
      result = subject.invoke(:main, [], {})
      expect(subject.shell).to have_received(:say).with('core_7-0-0').once
    end
  end

  describe '#readable' do
    before(:context) do
      @testprofile = 'test_1-1-1'
      origstr = %q[
{"allowDeleteHierarchyLeaves":false,"autocompleteFindDelay":500,"autocompleteMinLength":3,"basename":"/cspace/profile","className":"cspace-ui-plugin-profile-profile--common","container":"#cspace","defaultAdvancedSearchBooleanOp":"and","defaultDropdownFilter":"substring","defaultUserPrefs":{"panels":{"collectionobject":{"mediaSnapshotPanel":{"collapsed":false}}}},"index":"/search","locale":"en-US"}
      ]
      @profilepath = "#{CCU.configdir}/#{@testprofile}.json"
      File.open(@profilepath, 'w') { |file| file.write(origstr) }
    end

    after(:context){ File.delete(@profilepath) }

    it 'reformats profiles' do
      allow(subject.shell).to receive(:say)
      result = subject.invoke(:readable, [], {'profiles'=>@testprofile})
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
