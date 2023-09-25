require 'rails_helper'
require 'example_campaign_generator'

RSpec.describe ExampleCampaignGenerator do
  let(:expected_json) { IO.read(Rails.root.join("spec/fixtures/example-hpv-campaign-42.json")) }

  it "generates the expected campaign json" do
    json = nil
    # Patient's dob is generated as an age calculated from "now", so we need to
    # freeze time to get consistent ages calculated.
    Timecop.freeze(2023, 9, 25) do
      generator = ExampleCampaignGenerator.new(seed: 42, type: :hpv)
      json = JSON.pretty_generate(generator.generate)
    end
    expect(json).to eq(expected_json)
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
