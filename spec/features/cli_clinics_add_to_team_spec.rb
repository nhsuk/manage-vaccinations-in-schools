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

  context "when the school belongs to another subteam" do
    it "displays a warning message" do
      given_the_team_exists
      and_the_subteam_exists
      and_the_clinic_exists
      and_the_clinic_belongs_to_another_subteam

      when_i_run_the_command
      then_a_clinic_belongs_to_another_team_warning_message_is_displayed
      then_the_clinic_is_added_to_the_team
      and_the_clinic_remains_in_the_other_team_too
    end
  end

  private

  def command
    Dry::CLI.new(MavisCLI).call(
      arguments: %w[clinics add-to-team abc Team Clinic]
    )
  end

  def given_the_team_exists
    @team = create(:team, workgroup: "abc")
  end

  def and_the_subteam_exists
    @subteam = create(:subteam, name: "Team", team: @team)
  end

  def and_the_clinic_exists
    @clinic = create(:community_clinic, name: "Clinic", ods_code: "123456")
  end

  def and_the_clinic_belongs_to_another_subteam
    @other_team = create(:team, name: "Other Team")
    @other_subteam = create(:subteam, name: "Other Subteam", team: @other_team)
    @clinic.attach_to_team!(
      @other_team,
      academic_year: AcademicYear.pending,
      subteam: @other_subteam
    )
  end

  def when_i_run_the_command
    @output = capture_error { command }
  end

  def when_i_run_the_command_expecting_an_error
    @output = capture_error { command }
  end

  def then_an_team_not_found_error_message_is_displayed
    expect(@output).to include("Could not find team with workgroup abc.")
  end

  def then_a_subteam_not_found_error_message_is_displayed
    expect(@output).to include("Could not find subteam with name Team.")
  end

  def then_a_clinic_not_found_error_message_is_displayed
    expect(@output).to include("Could not find clinic with name Clinic.")
  end

  def then_a_clinic_belongs_to_another_team_warning_message_is_displayed
    expect(@output).to include("Clinic previously belonged to Other Subteam.")
  end

  def then_the_clinic_is_added_to_the_team
    expect(@team.community_clinics).to include(@clinic)
  end

  def and_the_clinic_remains_in_the_other_team_too
    expect(@other_team.community_clinics).to include(@clinic)
  end
end
