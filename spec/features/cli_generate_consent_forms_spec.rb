# frozen_string_literal: true

require_relative "../../app/lib/mavis_cli"

describe "mavis generate consent-forms" do
  it "generates consent forms for a session" do
    given_a_session_exists
    and_there_are_patients_in_the_session

    when_i_run_the_command
    then_consent_forms_are_created
    and_the_output_shows_progress
  end

  context "consent form matching" do
    it "matches consent forms with patients" do
      given_a_session_exists
      and_there_are_patients_in_the_session

      when_i_run_the_command
      then_consent_forms_are_matched_with_patients
    end
  end

  private

  def given_a_session_exists
    @team = create(:team)
    @session = create(:session, team: @team)
  end

  def and_there_are_patients_in_the_session
    @patients = create_list(:patient, 10, session: @session)
  end

  def when_i_run_the_command
    @output =
      capture_output do
        Dry::CLI.new(MavisCLI).call(
          arguments: ["generate", "consent-forms", @session.slug]
        )
      end
  end

  def then_consent_forms_are_created
    consent_forms = @session.location.consent_forms

    expect(consent_forms.count).to be > 0
  end

  def then_consent_forms_are_matched_with_patients
    consent_forms = @session.location.consent_forms.includes(:consents)

    expect(consent_forms.all? { it.consents.sole.patient.present? }).to be(true)

    consent_forms.each do |cf|
      patient = cf.consents.sole.patient
      expect(cf.given_name).to eq(patient.given_name)
      expect(cf.family_name).to eq(patient.family_name)
      expect(cf.date_of_birth).to eq(patient.date_of_birth)
    end
  end

  def and_the_output_shows_progress
    expect(@output).to include("Found #{@patients.count} patients")
    expect(@output).to include("Generating consent forms...")
    expect(@output).to include("Successfully generated consent forms")
  end
end
