require "spec_helper"

require "fileutils"

RSpec.describe CCU::ProfileComparison do
  subject(:compare) { described_class }

  before do
    ["anthro_7-0-0.json", "ohc_1-0-18_7-2.json"].each do |filename|
      FileUtils.cp(
        File.join(fixtures, "configs", filename),
        File.join(CCU.configdir, filename)
      )
    end
    CCU.config.main_profile_name = "anthro_7-0-0"
    # CCU.config.configdir = File.join("data", "configs")
  end

  after do
    FileUtils.rm(File.join(fixtures,
      "compare_anthro_7-0-0_to_ohc_1-0-18_7-2.csv"))
  end

  let(:expected_path) do
    File.join(fixtures, "files", "7_2",
      "compare_anthro_7-0-0_to_ohc_1-0-18_7-2.csv")
  end
  let(:profiles) { ["anthro_7-0-0", "ohc_1-0-18_7-2"] }
  let(:outputdir) { fixtures }
  let(:result_path) do
    File.join(fixtures, "compare_anthro_7-0-0_to_ohc_1-0-18_7-2.csv")
  end

  it "generates expected csvdata", skip: "skip until form extraction fixed" do
    compare.new(profiles, outputdir).write_csv
    expect(result_path).to match_csv(expected_path)
  end
end
