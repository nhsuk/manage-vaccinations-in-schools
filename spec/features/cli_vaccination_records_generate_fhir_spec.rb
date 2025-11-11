# frozen_string_literal: true

require_relative "../../app/lib/mavis_cli"

describe "mavis vaccination-records generate-fhir" do
  context "when the vaccination record exists and is administered" do
    it "generates and displays the FHIR record" do
      given_a_vaccination_record_exists
      when_i_run_the_generate_fhir_command
      then_the_fhir_record_is_displayed
    end
  end

  context "when the vaccination record does not exist" do
    it "displays an error message" do
      when_i_run_the_generate_fhir_command_with_an_invalid_id
      then_an_error_message_is_displayed
    end
  end

  context "when the vaccination record was not administered" do
    it "displays an error message with the reason" do
      given_a_not_administered_vaccination_record_exists
      when_i_run_the_generate_fhir_command_for_not_administered_record
      then_the_not_administered_error_message_is_displayed
    end
  end

  private

  def given_a_vaccination_record_exists
    team = create(:team)
    programme = Programme.hpv
    patient = create(:patient, team:)
    vaccine = programme.vaccines.first
    batch = create(:batch, vaccine:, expiry: "2023-03-20", name: "X8U375AL")

    @vaccination_record =
      create(
        :vaccination_record,
        patient:,
        programme:,
        vaccine:,
        batch:,
        outcome: "administered"
      )
  end

  def given_a_not_administered_vaccination_record_exists
    team = create(:team)
    programme = Programme.hpv
    patient = create(:patient, team:)

    @not_administered_vaccination_record =
      create(:vaccination_record, patient:, programme:, outcome: "refused")
  end

  def when_i_run_the_generate_fhir_command
    @output =
      capture_output do
        Dry::CLI.new(MavisCLI).call(
          arguments: [
            "vaccination-records",
            "generate-fhir",
            @vaccination_record.id
          ]
        )
      end
  end

  def when_i_run_the_generate_fhir_command_with_an_invalid_id
    @output =
      capture_output do
        Dry::CLI.new(MavisCLI).call(
          arguments: %w[vaccination-records generate-fhir 999999]
        )
      end
  end

  def when_i_run_the_generate_fhir_command_for_not_administered_record
    @output =
      capture_output do
        Dry::CLI.new(MavisCLI).call(
          arguments: [
            "vaccination-records",
            "generate-fhir",
            @not_administered_vaccination_record.id
          ]
        )
      end
  end

  def then_the_fhir_record_is_displayed
    expect(@output).to include("resourceType")
    expect(@output).to include("Immunization")
    # We expect the JSON output to be pretty-printed
    expect(@output).to include("{\n")
  end

  def then_an_error_message_is_displayed
    expect(@output).to include(
      "Error: Vaccination record with ID 999999 not found"
    )
  end

  def then_the_not_administered_error_message_is_displayed
    outcome = @not_administered_vaccination_record.outcome.humanize
    expect(@output).to include(
      "Error: Vaccination record with ID #{@not_administered_vaccination_record.id} was not " \
        "administered (Outcome: #{outcome})"
    )
  end
end
