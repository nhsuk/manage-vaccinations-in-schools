# frozen_string_literal: true

require_relative "../../app/lib/mavis_cli"

describe "mavis schools remove-from-team" do
  context "with valid arguments" do
    it "runs successfully" do
      given_schools_exist
      when_i_run_the_command
      then_the_schools_are_removed_from_the_team
    end
  end

  private

  def given_schools_exist
    team = create(:team, workgroup: "TeamA")
    subteam = create(:subteam, team:, name: "SubteamA")
    @school_a =
      create(
        :school,
        urn: "123456",
        name: "MainSchool",
        site: nil,
        team:,
        subteam:
      )
    @school_b =
      create(
        :school,
        urn: "654321",
        name: "OtherSchool",
        site: nil,
        team:,
        subteam:
      )
    expect(@school_a.teams.count).to eq(1)
    expect(@school_b.teams.count).to eq(1)
  end

  def command
    Dry::CLI.new(MavisCLI).call(
      arguments: %w[
        schools
        remove-from-team
        TeamA
        SubteamA
        123456
        654321
        --academic-year
        2025
      ]
    )
  end

  def when_i_run_the_command
    @output = capture_output { command }
  end

  def then_the_schools_are_removed_from_the_team
    expect(@school_a.teams.count).to eq(0)
    expect(@school_b.teams.count).to eq(0)
  end
end
