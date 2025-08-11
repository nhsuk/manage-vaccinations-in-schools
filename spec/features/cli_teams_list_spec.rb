# frozen_string_literal: true

require_relative "../../app/lib/mavis_cli"

describe "mavis teams list" do
  it "lists all teams" do
    given_a_couple_organisations_exist
    and_there_are_teams_in_the_organisations
    when_i_run_the_list_teams_command
    then_i_should_see_the_list_of_teams
  end

  it "lists teams for one org" do
    given_a_couple_organisations_exist
    and_there_are_teams_in_the_organisations
    when_i_run_the_list_teams_command_with_an_ods_code
    then_i_should_see_the_teams_for_just_that_ods_code
  end

  def given_a_couple_organisations_exist
    @organisation1 = create(:organisation)
    @organisation2 = create(:organisation)
  end

  def and_there_are_teams_in_the_organisations
    @team1 = create(:team, organisation: @organisation1)
    @team2 = create(:team, organisation: @organisation2)
  end

  def when_i_run_the_list_teams_command
    @output =
      capture_output { Dry::CLI.new(MavisCLI).call(arguments: %w[teams list]) }
  end

  def when_i_run_the_list_teams_command_with_an_ods_code
    @output =
      capture_output do
        Dry::CLI.new(MavisCLI).call(
          arguments: ["teams", "list", "-o", @organisation1.ods_code]
        )
      end
  end

  def then_i_should_see_the_list_of_teams
    expect(@output).to include(@team1.name)
    expect(@output).to include(@organisation1.ods_code)
    expect(@output).to include(@team1.workgroup)
    expect(@output).to include(@team2.name)
    expect(@output).to include(@organisation2.ods_code)
    expect(@output).to include(@team2.workgroup)
  end

  def then_i_should_see_the_teams_for_just_that_ods_code
    expect(@output).to include(@team1.name)
    expect(@output).to include(@organisation1.ods_code)
    expect(@output).to include(@team1.workgroup)
    expect(@output).not_to include(@team2.name)
    expect(@output).not_to include(@organisation2.ods_code)
    expect(@output).not_to include(@team2.workgroup)
  end
end
