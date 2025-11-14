# frozen_string_literal: true

require_relative "../../app/lib/mavis_cli"

describe "mavis teams onboard" do
  context "with a valid configuration" do
    it "runs successfully" do
      given_programmes_and_schools_exist
      when_i_run_the_valid_command
      then_i_see_no_output
      and_a_new_team_is_created
    end
  end

  context "with an invalid configuration" do
    it "displays an error message" do
      when_i_run_the_invalid_command
      then_i_see_an_error_message
    end
  end

  context "with a training configuration", :local_users do
    it "runs successfully" do
      given_programmes_and_schools_exist
      when_i_run_the_command_for_training
      then_i_see_no_output
      and_a_new_team_is_created
    end
  end

  def command_with_valid_configuration
    Dry::CLI.new(MavisCLI).call(
      arguments: %w[teams onboard spec/fixtures/files/onboarding/valid.yaml]
    )
  end

  def command_with_invalid_configuration
    Dry::CLI.new(MavisCLI).call(
      arguments: %w[teams onboard spec/fixtures/files/onboarding/invalid.yaml]
    )
  end

  def command_for_training
    Dry::CLI.new(MavisCLI).call(
      arguments: %w[
        teams
        onboard
        --training
        --ods-code=EXAMPLE
        --workgroup=nhstrust
      ]
    )
  end

  def given_programmes_and_schools_exist
    Programme.hpv

    create(:school, :secondary, :open, urn: "123456")
    create(:school, :secondary, :open, urn: "234567")
    create(:school, :secondary, :open, urn: "345678")
    create(:school, :secondary, :open, urn: "456789")
  end

  def when_i_run_the_valid_command
    @output = capture_output { command_with_valid_configuration }
  end

  def when_i_run_the_invalid_command
    @output = capture_output { command_with_invalid_configuration }
  end

  def when_i_run_the_command_for_training
    @output = capture_output { command_for_training }
  end

  def then_i_see_no_output
    expect(@output).to be_empty
  end

  def and_a_new_team_is_created
    expect(Team.count).to eq(1)
  end

  def then_i_see_an_error_message
    expect(@output).to include("Programmes can't be blank")
  end
end
