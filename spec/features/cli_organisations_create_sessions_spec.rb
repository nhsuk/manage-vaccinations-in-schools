# frozen_string_literal: true

require_relative "../../app/lib/mavis_cli"

describe "mavis organisations create-sessions" do
  context "when the organisation doesn't exist" do
    it "displays an error message" do
      when_i_run_the_command_expecting_an_error
      then_an_organisation_not_found_error_message_is_displayed
    end
  end

  context "when the organisation exists" do
    it "runs successfully" do
      given_the_organisation_exists
      and_the_school_exists

      when_i_run_the_command
      then_the_school_session_is_created
    end
  end

  private

  def command
    Dry::CLI.new(MavisCLI).call(
      arguments: %w[organisations create-sessions ABC]
    )
  end

  def given_the_organisation_exists
    @programmes = [create(:programme, :flu), create(:programme, :hpv)]
    @organisation =
      create(:organisation, ods_code: "ABC", programmes: @programmes)
  end

  def and_the_school_exists
    @school =
      create(
        :school,
        name: "School",
        urn: "123456",
        organisation: @organisation
      )
  end

  def when_i_run_the_command
    @output = capture_output { command }
  end

  def when_i_run_the_command_expecting_an_error
    @output = capture_error { command }
  end

  def then_an_organisation_not_found_error_message_is_displayed
    expect(@output).to include("Could not find organisation.")
  end

  def then_the_school_session_is_created
    expect(@organisation.sessions).not_to be_empty

    session = @organisation.sessions.includes(:location).first
    expect(session.location).to eq(@school)
  end
end
