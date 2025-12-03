# frozen_string_literal: true

require_relative "../../app/lib/mavis_cli"

describe "mavis vaccination-records sync" do
  before do
    Flipper.enable(:imms_api_integration)
    Flipper.enable(:imms_api_sync_job, Programme.hpv)
  end

  after do
    Flipper.disable(:imms_api_integration)
    Flipper.disable(:imms_api_sync_job)
  end

  context "when the vaccination record exists and has not been synced" do
    it "syncs the vaccination record to the NHS API" do
      given_a_vaccination_record_exists
      and_the_nhs_api_is_available
      when_i_run_the_sync_command
      then_the_vaccination_record_is_synced_to_the_immunisations_api
    end
  end

  context "when the vaccination record does not exist" do
    it "displays an error message" do
      when_i_run_the_sync_command_with_an_invalid_id
      then_an_error_message_is_displayed
    end
  end

  context "when the vaccination record has already been synced" do
    it "displays a message indicating it has already been synced" do
      given_a_synced_vaccination_record_exists
      when_i_run_the_sync_command_for_synced_record
      then_the_already_synced_message_is_displayed
    end
  end

  context "when the imms_api_integration feature flag is disabled" do
    before { Flipper.disable :imms_api_integration }

    it "displays a message indicating the feature flag is disabled" do
      given_a_vaccination_record_exists
      when_i_run_the_sync_command
      then_the_feature_flag_disabled_message_is_displayed
    end
  end

  private

  def given_a_vaccination_record_exists
    team = create(:team)
    programme = Programme.hpv
    session = create(:session, programmes: [programme], team:)
    patient = create(:patient, team:)
    vaccine = programme.vaccines.find_by!(brand: "Gardasil")
    batch = create(:batch, vaccine:, expiry: "2023-03-20", name: "X8U375AL")

    @vaccination_record =
      create(
        :vaccination_record,
        patient:,
        programme:,
        vaccine:,
        batch:,
        session:,
        nhs_immunisations_api_synced_at: nil
      )
  end

  def given_a_synced_vaccination_record_exists
    team = create(:team)
    programme = Programme.hpv
    patient = create(:patient, team:)
    @synced_vaccination_record =
      create(
        :vaccination_record,
        patient:,
        programme:,
        nhs_immunisations_api_synced_at: Time.current,
        nhs_immunisations_api_id: Random.uuid,
        nhs_immunisations_api_primary_source: true
      )
  end

  def and_the_nhs_api_is_available
    @nhs_api_request =
      stub_request(
        :post,
        "https://sandbox.api.service.nhs.uk/immunisation-fhir-api/FHIR/R4/Immunization"
      ).with(
        headers: {
          "Content-Type" => "application/fhir+json",
          "Accept" => "application/fhir+json"
        }
      ).to_return(
        status: 201,
        body: "",
        headers: {
          location:
            "https://sandbox.api.service.nhs.uk/immunisation-fhir-api/Immunization/11112222-3333-4444-5555-666677778888"
        }
      )
  end

  def when_i_run_the_sync_command
    @output =
      capture_output do
        Dry::CLI.new(MavisCLI).call(
          arguments: ["vaccination-records", "sync", @vaccination_record.id]
        )
      end
  end

  def when_i_run_the_sync_command_with_an_invalid_id
    @output =
      capture_output do
        Dry::CLI.new(MavisCLI).call(
          arguments: %w[vaccination-records sync 999999]
        )
      end
  end

  def when_i_run_the_sync_command_for_synced_record
    @output =
      capture_output do
        Dry::CLI.new(MavisCLI).call(
          arguments: [
            "vaccination-records",
            "sync",
            @synced_vaccination_record.id
          ]
        )
      end
  end

  def then_the_vaccination_record_is_synced_to_the_immunisations_api
    expect(@nhs_api_request).to have_been_made
    expect(@output).to include(
      "Successfully synced vaccination record #{@vaccination_record.id}"
    )
  end

  def then_an_error_message_is_displayed
    expect(@output).to include("Vaccination record with ID 999999 not found")
  end

  def then_the_already_synced_message_is_displayed
    expect(@output).to include("has already been synced at")
  end

  def then_the_feature_flag_disabled_message_is_displayed
    expect(@output).to include(
      "Cannot sync vaccination record: the `imms_api_integration` feature flag is disabled"
    )
  end
end
