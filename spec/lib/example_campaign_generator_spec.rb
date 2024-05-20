require "rails_helper"
require "example_campaign_generator"

RSpec.describe ExampleCampaignGenerator do
  let(:test_timestamp) { [2024, 5, 20, 12, 0, 0] }

  let(:expected_hpv_json) do
    # Remove final newline if present to match generated JSON.
    File.read(
      Rails.root.join("db/sample_data/example-hpv-campaign.json")
    ).rstrip
  end
  let(:expected_flu_json) do
    # Remove final newline if present to match generated JSON.
    File.read(
      Rails.root.join("db/sample_data/example-flu-campaign.json")
    ).rstrip
  end
  let(:expected_pilot_json) do
    # Remove final newline if present to match generated JSON.
    File.read(
      Rails.root.join("db/sample_data/example-pilot-campaign.json")
    ).rstrip
  end

  it "generates the expected HPV campaign json" do
    json = nil
    # Patient's dob is generated as an age calculated from when the fixture json
    # was generated, so we freeze time to the same day it was generated to get
    # the same random ages.
    #
    # When the fixture json is regenerated, e.g. when the generater is updated,
    # the time here will need to be changed to match the day when it was
    # generated.
    #
    # To regenerate:
    #     bin/generate-example-campaigns
    Timecop.freeze(*test_timestamp) do
      generator =
        ExampleCampaignGenerator.new(
          seed: 42,
          type: :hpv,
          presets: "default",
          username: "Nurse Joy"
        )
      data = generator.generate
      json = JSON.pretty_generate(data)
    end
    expect(json).to eq(expected_hpv_json)
  end

  it "generates the expected flu campaign json" do
    json = nil
    # Patient's dob is generated as an age calculated from when the fixture json
    # was generated, so we freeze time to the same day it was generated to get
    # the same random ages.
    #
    # When the fixture json is regenerated, e.g. when the generater is updated,
    # the time here will need to be changed to match the day when it was
    # generated.
    #
    # To regenerate:
    #     bin/generate-example-campaigns
    Timecop.freeze(*test_timestamp) do
      generator =
        ExampleCampaignGenerator.new(
          seed: 43,
          type: :flu,
          presets: "default",
          username: "Nurse Jackie"
        )
      data = generator.generate
      json = JSON.pretty_generate(data)
    end
    expect(json).to eq(expected_flu_json)
  end

  it "generates the expected empty pilot campaign json" do
    json = nil
    # Patient's dob is generated as an age calculated from when the fixture json
    # was generated, so we freeze time to the same day it was generated to get
    # the same random ages.
    #
    # When the fixture json is regenerated, e.g. when the generater is updated,
    # the time here will need to be changed to match the day when it was
    # generated.
    #
    # To regenerate:
    #     bin/generate-example-campaigns
    Timecop.freeze(*test_timestamp) do
      generator =
        ExampleCampaignGenerator.new(
          seed: 44,
          presets: "empty_pilot",
          username: "Nurse Flo"
        )
      data = generator.generate
      json = JSON.pretty_generate(data)
    end
    expect(json).to eq(expected_pilot_json)
  end

  describe "setting the campaign type" do
    it "generates an flu campaign by default" do
      generator = ExampleCampaignGenerator.new
      expect(generator.type).to eq(:flu)
    end

    it "allows overriding of the campaign type" do
      generator = ExampleCampaignGenerator.new(type: :hpv)
      expect(generator.type).to eq(:hpv)
    end

    it "generates an hpv campaign for the model office" do
      generator =
        ExampleCampaignGenerator.new(
          presets: :model_office,
          username: "Nurse Test"
        )
      expect(generator.type).to eq(:hpv)
    end

    it "allows overriding of model office campaign type" do
      generator =
        ExampleCampaignGenerator.new(
          presets: :model_office,
          type: :flu,
          username: "Nurse Test"
        )
      expect(generator.type).to eq(:flu)
    end

    it "raises an error when an invalid type is specified" do
      expect { ExampleCampaignGenerator.new(type: :invalid) }.to raise_error(
        ArgumentError,
        /invalid type/i
      )
    end
  end

  # The existing model office campaign generator generates the following:
  #
  #   Triage screens:
  #     - Needs triage: 18
  #       - Triage: 14
  #       - Triage started: 4
  #     - Triage complete: 14 (vaccinate/do not vaccinate is randomly assigned, so numbers may change)
  #       - Vaccinate: 7
  #       - Do not vaccinate: 7
  #     - Get consent: 16
  #     - No triage neeeded: 39
  #       - Vaccinate: 24
  #       - Check refusal: 15
  #   Record vaccinations screens:
  #     - Action needed: 80
  #       - Triage: 14
  #       - Triage started: 4
  #       - Vaccinate: 31
  #       - Get consent: 16
  #       - Check refusal: 15
  #     - Vaccinated: 0
  #     - Not vaccinated: 7
  #       - Do not vaccinate: 7
  #
  # We could test these are correctly generated, but it would mean loading the
  # JSON data.
end
