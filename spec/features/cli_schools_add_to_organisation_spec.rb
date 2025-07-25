# frozen_string_literal: true

require_relative "../../app/lib/mavis_cli"

describe "mavis schools add-to-organisation" do
  context "when the organisation doesn't exist" do
    it "displays an error message" do
      when_i_run_the_command_expecting_an_error
      then_an_organisation_not_found_error_message_is_displayed
    end
  end

  context "when the team doesn't exist" do
    it "displays an error message" do
      given_the_organisation_exists

      when_i_run_the_command_expecting_an_error
      then_a_team_not_found_error_message_is_displayed
    end
  end

  context "when the school doesn't exist" do
    it "displays an error message" do
      given_the_organisation_exists
      and_the_team_exists

      when_i_run_the_command_expecting_an_error
      then_a_school_not_found_error_message_is_displayed
    end
  end

  context "when the school exists" do
    it "runs successfully" do
      given_the_organisation_exists
      and_the_team_exists
      and_the_school_exists

      when_i_run_the_command
      then_the_school_is_added_to_the_organisation
    end
  end

  context "when customising the programmes" do
    it "runs successfully" do
      given_the_organisation_exists
      and_the_team_exists
      and_the_school_exists

      when_i_run_the_command_with_flu_only
      then_the_school_is_added_to_the_organisation_with_flu_only
    end
  end

  private

  def command
    Dry::CLI.new(MavisCLI).call(
      arguments: %w[schools add-to-organisation ABC Team 123456]
    )
  end

  def command_with_flu_only
    Dry::CLI.new(MavisCLI).call(
      arguments: %w[
        schools
        add-to-organisation
        ABC
        Team
        123456
        --programmes
        flu
      ]
    )
  end

  def given_the_organisation_exists
    @programmes = [create(:programme, :flu), create(:programme, :hpv)]
    @organisation =
      create(:organisation, ods_code: "ABC", programmes: @programmes)
  end

  def and_the_team_exists
    @team = create(:team, name: "Team", organisation: @organisation)
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

  def then_an_organisation_not_found_error_message_is_displayed
    expect(@output).to include("Could not find organisation.")
  end

  def then_a_team_not_found_error_message_is_displayed
    expect(@output).to include("Could not find team.")
  end

  def then_a_school_not_found_error_message_is_displayed
    expect(@output).to include("Could not find location: 123456")
  end

  def then_the_school_is_added_to_the_organisation
    expect(@organisation.schools).to include(@school)
    expect(@school.programmes).to eq(@programmes)
  end

  def then_the_school_is_added_to_the_organisation_with_flu_only
    expect(@organisation.schools).to include(@school)
    expect(@school.programmes).to contain_exactly(@programmes.first)
  end
end
