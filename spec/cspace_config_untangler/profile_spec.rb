# frozen_string_literal: true

require "spec_helper"

RSpec.describe CCU::Profile do
  let(:release) { "6_1" }
  let(:rectypes) { ["person"] }
  let(:generator) {
    Helpers::SetupGenerator.new(profile: profilename, rectypes: rectypes,
      release: release)
  }
  let(:profile) { generator.profile }

  let(:core_rectypes) do
    [
      "acquisition", "citation", "collectionobject", "concept", "conditioncheck", "conservation", "exhibition",
      "group", "intake", "loanin", "loanout", "location", "media", "movement", "objectexit", "organization",
      "person", "place", "uoc", "valuation", "work"
    ]
  end

  let(:core_authorities) do
    %w[
      citation/local citation/worldcat concept/activity concept/associated concept/material
      concept/nomenclature concept/occasion location/local location/offsite organization/local
      organization/ulan person/local person/ulan place/local place/tgn work/cona work/local
    ]
  end

  let(:core_option_lists) do
    %w[
      dimensions measurementUnits searchResultPagePageSizes searchPanelPageSizes booleans
      yesNoValues dateQualifiers departments loanPurposes accountStatuses acquisitionMethods
      citationTermStatuses ageUnits collections contentObjectTypes forms inscriptionTypes measuredParts
      measurementMethods nameCurrencies nameLevels nameSystems nameTypes numberTypes objectComponentNames
      objectStatuses ownershipAccessLevels ownershipCategories ownershipExchangeMethods phases positions
      recordStatuses scripts sexes technicalAttributes technicalAttributeMeasurements
      technicalAttributeMeasurementUnits titleTypes objectParentTypes objectChildTypes conceptTermStatuses
      conceptTermTypes conceptHistoricalStatuses objectAuditCategories completenessLevels conditions
      conservationTreatmentPriorities hazards conditionCheckMethods conditionCheckReasons salvagePriorityCodes
      emailTypes telephoneNumberTypes faxNumberTypes webAddressTypes addressTypes addressCountries
      exhibitionConsTreatmentStatuses exhibitionMountStatuses entryReasons locationTermTypes
      locationTermStatuses mediaTypes locationFitnesses moveReasons moveMethods invActions invFreqs exitReasons
      exitMethods orgTermTypes orgTermStatuses personTermStatuses personTermTypes salutations personTitles
      genders placeTermTypes placeTermStatuses placeHistoricalStatuses placeTypes coordinateSystems
      spatialRefSystems localityUnits geodeticDatums geoRefProtocols geoRefVerificationStatuses
      reportMimeTypes valueTypes vocabTermStatuses workTermStatuses
    ].sort
  end

  let(:core_vocabs) do
    %w[
      addresstype agentinfotype agequalifier citationtermflag citationtermtype collectionmethod
      concepttermflag concepttype conditioncheckmethod conditioncheckreason conditionfitness
      conservationstatus contactrole contactstatus currency datecertainty dateera datequalifier
      deaccessionapprovalgroup deaccessionapprovalstatus disposalmethod entrymethod examinationphase
      exhibitionpersonrole exhibitionreferencetype exhibitionstatus exhibitiontype inventorystatus
      languages loanoutstatus locationtermflag locationtype organizationtype orgtermflag otherpartyrole
      persontermflag persontermtype placetermflag publishto relationtypetype resourceidtype treatmentpurpose
      uocauthorizationstatuses uoccollectiontypes uocmaterialtypes uocmethods uocprojectid uocstaffroles
      uocsubcollections uocuserroles uocusertypes workcreatortype workpublishertype worktermflag worktype
    ].sort
  end

  context "when core" do
    let(:profilename) { "core" }

    describe ".new" do
      it "creates CCU::Profile object" do
        expect(profile).to be_instance_of(CCU::Profile)
      end
    end

    describe ".config" do
      context "when 5_2" do
        let(:release) { "5_2" }
        it "returns hash" do
          expect(profile.config).to be_instance_of(Hash)
        end

        it "hash for core 5.2 has 28 keys" do
          expect(profile.config.keys.length).to eq(28)
        end
      end
    end

    describe ".rectypes" do
      let(:rectypes) { [] }
      it "returns array" do
        expect(profile.rectypes).to be_instance_of(Array)
      end

      it "cleans rectype list" do
        expect(profile.rectypes.map { |rt| rt.name }.sort).to eq(core_rectypes)
      end
    end

    describe ".extensions" do
      it "returns array" do
        expect(profile.extensions).to be_instance_of(Array)
      end

      it "cleans extension list" do
        expect(profile.extensions.sort).to eq(%w[address blob contact dimension
          structuredDate])
      end
    end

    describe ".authorities" do
      let(:result) { profile.authorities }

      context "when all rectypes requested" do
        let(:rectype) { [] }
        it "returns array" do
          expect(result).to be_instance_of(Array)
        end

        it "returns expected authorities" do
          expect(result.sort).to eq(core_authorities.sort)
        end
      end

      context "when only collectionobject requested" do
        let(:rectype) { ["collectionobject"] }
        it "returns expected authorities" do
          expect(result.sort).to eq(core_authorities.sort)
        end
      end
    end
  end

  context "when anthro" do
    let(:profilename) { "anthro" }

    describe "apply_panel_override" do
      it "gets panel message overrides from profile level" do
        msg = profile.messages["panel.collectionobject.reference"]["fullName"]
        expect(msg).to eq("Bibliographic Reference Information")
      end
    end
  end

  context "when bonsai" do
    let(:profilename) { "bonsai" }
    let(:rectypes) { ["conservation"] }

    describe "apply_overrides" do
      it "gives living plant extension messages ext prefix instead of conservation_livingplant" do
        expect(profile.messages.has_key?("field.ext.livingplant.pestOrDiseaseObserved")).to be true
      end
    end

    describe "apply_field_override" do
      it "gets field message overrides from profile level" do
        msg = profile.messages["field.conservation_common.conservator"]["name"]
        expect(msg).to eq("Performed by")
      end
    end
  end

  describe ".option_lists" do
    let(:profilename) { "core" }
    it "returns array" do
      expect(profile.option_lists).to be_a(CCU::OptionLists)
    end

    it "returns expected option_lists" do
      expect(profile.option_lists.names.sort).to eq(core_option_lists.sort)
    end
  end

  describe "#extensions_for" do
    let(:profilename) { "anthro" }
    let(:result) { profile.extensions_for("collectionobject") }
    it "returns hash" do
      expect(result).to be_instance_of(Hash)
    end
    it "keys are the extension names" do
      a = %w[address dimension structuredDate annotation culturalcare locality
        naturalhistory nagpra].sort
      expect(result.keys.sort).to eq(a)
    end
  end

  describe "vocabularies" do
    let(:profilename) { "core" }
    it "returns array of vocabularies",
      skip: "unnecessary if mapper and template output is as expected" do
      result = profile.vocabularies.sort
      puts "In actual result, not in expected"
      puts result - core_vocabs
      puts "In expected, not in actual result"
      puts core_vocabs - result
      expect(result).to eq(core_vocabs)
    end
  end

  describe "special_rectypes" do
    let(:profilename) { "core" }

    context "no rectypes given" do
      let(:rectypes) { [] }
      it "returns objecthierarchy, authorityhierarchy, relationship" do
        expected = %w[authorityhierarchy nonhierarchicalrelationship
          objecthierarchy]
        expect(profile.special_rectypes.map(&:name).sort).to eq(expected)
      end
    end

    context "rectypes = collectionobject" do
      let(:rectypes) { ["collectionobject"] }
      it "returns objecthierarchy, relationship" do
        expect(profile.special_rectypes.map(&:name).sort).to eq(%w[
          nonhierarchicalrelationship objecthierarchy
        ])
      end
    end

    context "rectypes = work" do
      let(:rectypes) { ["work"] }
      it "returns authorityhierarchy" do
        expect(profile.special_rectypes.map(&:name).sort).to eq(%w[authorityhierarchy])
      end
    end

    context "rectypes = acquisition" do
      let(:rectypes) { ["acquisition"] }
      it "returns relationship" do
        expect(profile.special_rectypes.map(&:name).sort).to eq(%w[nonhierarchicalrelationship])
      end
    end
  end

  context "filename dependent" do
    before(:context) { Helpers.set_profile_release("6_1") }

    let(:profile) { CCU::Profile.new(profile: "anthro_4-1-2") }

    describe "#basename" do
      it "returns anthro" do
        expect(profile.basename).to eq("anthro")
      end
    end
    describe "#version" do
      it "returns version" do
        expect(profile.version).to eq("4-1-2")
      end
    end
  end
end
