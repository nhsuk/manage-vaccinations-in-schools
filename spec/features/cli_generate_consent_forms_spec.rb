# frozen_string_literal: true

require_relative "../../app/lib/mavis_cli"

describe "mavis generate consent-forms" do
  it "generates consent forms" do
    given_a_session_exists
    and_there_are_three_patients_in_the_session

    when_i_run_the_command
    then_consent_forms_are_created
  end

  def given_a_session_exists
    @session = create(:session)
  end

  def and_there_are_three_patients_in_the_session
    create_list(:patient, 3, session: @session)
  end

  def command
    Dry::CLI.new(MavisCLI).call(
      arguments: ["generate", "consent-forms", @session.slug]
    )
  end

  def when_i_run_the_command
    @output = capture_output { command }
  end

  def then_consent_forms_are_created
    expect(@session.location.consent_forms).not_to be_empty
  end
end
