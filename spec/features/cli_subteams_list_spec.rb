# frozen_string_literal: true

require_relative "../../app/lib/mavis_cli"

describe "mavis subteams list" do
  include ActionView::Helpers::NumberHelper

  it "lists all subteams" do
    given_a_couple_teams_exist
    and_there_are_subteams_in_the_teams
    when_i_run_the_list_subteams_command
    then_i_should_see_the_list_of_subteams
  end

  it "lists subteams for one org" do
    given_a_couple_teams_exist
    and_there_are_subteams_in_the_teams
    when_i_run_the_list_subteams_command_with_a_workgroup
    then_i_should_see_the_subteams_for_just_that_team
  end

  context "Team does not exist" do
    it "returns an error message" do
      when_i_run_the_list_subteams_command_with_an_invalid_workgroup
      then_i_should_see_a_team_doesnt_exist_message
    end
  end

  def given_a_couple_teams_exist
    @programme = Programme.sample
    @team1 = create(:team, programmes: [@programme])
    @team2 = create(:team, programmes: [@programme])
  end

  def and_there_are_subteams_in_the_teams
    @subteam1 = create(:subteam, team: @team1)
    @subteam2 = create(:subteam, team: @team2)
  end

  def when_i_run_the_list_subteams_command
    @output =
      capture_output do
        Dry::CLI.new(MavisCLI).call(arguments: %w[subteams list])
      end
  end

  def when_i_run_the_list_subteams_command_with_a_workgroup
    @output =
      capture_output do
        Dry::CLI.new(MavisCLI).call(
          arguments: ["subteams", "list", "-t", @team1.workgroup]
        )
      end
  end

  def when_i_run_the_list_subteams_command_with_an_invalid_workgroup
    @output =
      capture_error do
        Dry::CLI.new(MavisCLI).call(
          arguments: %w[subteams list -t invalid_workgroup]
        )
      end
  end

  def then_i_should_see_the_list_of_subteams
    expect(@output).to include(
      "#{number_with_delimiter(@subteam1.id)} │ #{@subteam1.name}"
    )
    expect(@output).to include(
      "#{number_with_delimiter(@team1.id)} │ #{@team1.workgroup}"
    )
    expect(@output).to include(
      "#{number_with_delimiter(@subteam2.id)} │ #{@subteam2.name}"
    )
    expect(@output).to include(
      "#{number_with_delimiter(@team2.id)} │ #{@team2.workgroup}"
    )
    expect(@output).to include(@programme.name).twice
  end

  def then_i_should_see_the_subteams_for_just_that_team
    expect(@output).to include(
      "#{number_with_delimiter(@subteam1.id)} │ #{@subteam1.name}"
    )
    expect(@output).to include(
      "#{number_with_delimiter(@team1.id)} │ #{@team1.workgroup}"
    )
    expect(@output).not_to include(
      "#{number_with_delimiter(@subteam2.id)} │ #{@subteam2.name}"
    )
    expect(@output).not_to include(
      "#{number_with_delimiter(@team2.id)} │ #{@team2.workgroup}"
    )
    expect(@output).to include(@programme.name).once
  end

  def then_i_should_see_a_team_doesnt_exist_message
    expect(@output).to include(
      "Could not find team with workgroup invalid_workgroup."
    )
  end
end
