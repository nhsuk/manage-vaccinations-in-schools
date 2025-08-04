# frozen_string_literal: true

require_relative "../../app/lib/mavis_cli"

describe "mavis schools add-to-team" do
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

  context "when the school doesn't exist" do
    it "displays an error message" do
      given_the_team_exists
      and_the_subteam_exists

      when_i_run_the_command_expecting_an_error
      then_a_school_not_found_error_message_is_displayed
    end
  end

  context "when the school exists" do
    it "runs successfully" do
      given_the_team_exists
      and_the_subteam_exists
      and_the_school_exists

      when_i_run_the_command
      then_the_school_is_added_to_the_team
    end
  end

  context "when customising the programmes" do
    it "runs successfully" do
      given_the_team_exists
      and_the_subteam_exists
      and_the_school_exists

      when_i_run_the_command_with_flu_only
      then_the_school_is_added_to_the_team_with_flu_only
    end
  end

  private

  def command
    Dry::CLI.new(MavisCLI).call(
      arguments: %w[schools add-to-team ABC Team 123456]
    )
  end

  def command_with_flu_only
    Dry::CLI.new(MavisCLI).call(
      arguments: %w[schools add-to-team ABC Team 123456 --programmes flu]
    )
  end

  def given_the_team_exists
    @programmes = [create(:programme, :flu), create(:programme, :hpv)]
    @team = create(:team, ods_code: "ABC", programmes: @programmes)
  end

  def and_the_subteam_exists
    @subteam = create(:subteam, name: "Team", team: @team)
  end

  def and_the_school_exists
    @school = create(:school, name: "School", urn: "123456")
  end

  def when_i_run_the_command
    @output = capture_error { command }
  end

  def when_i_run_the_command_with_flu_only
    @output = capture_error { command_with_flu_only }
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

  def then_a_school_not_found_error_message_is_displayed
    expect(@output).to include("Could not find location: 123456")
  end

  def then_the_school_is_added_to_the_team
    expect(@team.schools).to include(@school)
    expect(@school.programmes).to eq(@programmes)
  end

  def then_the_school_is_added_to_the_team_with_flu_only
    expect(@team.schools).to include(@school)
    expect(@school.programmes).to contain_exactly(@programmes.first)
  end
end
