# frozen_string_literal: true

require_relative "../../app/lib/mavis_cli"

describe "mavis teams create-sessions" do
  context "when the team doesn't exist" do
    it "displays an error message" do
      when_i_run_the_command_expecting_an_error
      then_an_team_not_found_error_message_is_displayed
    end
  end

  context "when the team exists" do
    it "runs successfully" do
      given_the_team_exists
      and_the_school_exists

      when_i_run_the_command
      then_the_school_session_is_created
    end
  end

  private

  def command
    Dry::CLI.new(MavisCLI).call(arguments: %w[teams create-sessions ABC])
  end

  def given_the_team_exists
    @programmes = [create(:programme, :flu), create(:programme, :hpv)]
    @team = create(:team, ods_code: "ABC", programmes: @programmes)
  end

  def and_the_school_exists
    @school = create(:school, name: "School", urn: "123456", team: @team)
  end

  def when_i_run_the_command
    @output = capture_output { command }
  end

  def when_i_run_the_command_expecting_an_error
    @output = capture_error { command }
  end

  def then_an_team_not_found_error_message_is_displayed
    expect(@output).to include("Could not find team.")
  end

  def then_the_school_session_is_created
    expect(@team.sessions).not_to be_empty

    session = @team.sessions.includes(:location).first
    expect(session.location).to eq(@school)
  end
end
