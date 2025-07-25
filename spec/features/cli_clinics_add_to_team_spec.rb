# frozen_string_literal: true

require_relative "../../app/lib/mavis_cli"

describe "mavis clinics add-to-team" do
  context "when the team doesn't exist" do
    it "displays an error message" do
      when_i_run_the_command_expecting_an_error
      then_an_team_not_found_error_message_is_displayed
    end
  end

  context "when the subteam doesn't exist" do
    it "displays an error message" do
      given_the_team_exists

      when_i_run_the_command_expecting_an_error
      then_a_subteam_not_found_error_message_is_displayed
    end
  end

  context "when the clinic doesn't exist" do
    it "displays an error message" do
      given_the_team_exists
      and_the_subteam_exists

      when_i_run_the_command_expecting_an_error
      then_a_clinic_not_found_error_message_is_displayed
    end
  end

  context "when the clinic exists" do
    it "runs successfully" do
      given_the_team_exists
      and_the_subteam_exists
      and_the_clinic_exists

      when_i_run_the_command
      then_the_clinic_is_added_to_the_team
    end
  end

  private

  def command
    Dry::CLI.new(MavisCLI).call(
      arguments: %w[clinics add-to-team ABC Team 123456]
    )
  end

  def given_the_team_exists
    @team = create(:team, ods_code: "ABC")
  end

  def and_the_subteam_exists
    @subteam = create(:subteam, name: "Team", team: @team)
  end

  def and_the_clinic_exists
    @clinic = create(:community_clinic, name: "Clinic", ods_code: "123456")
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

  def then_a_subteam_not_found_error_message_is_displayed
    expect(@output).to include("Could not find subteam.")
  end

  def then_a_clinic_not_found_error_message_is_displayed
    expect(@output).to include("Could not find location: 123456")
  end

  def then_the_clinic_is_added_to_the_team
    expect(@team.community_clinics).to include(@clinic)
  end
end
