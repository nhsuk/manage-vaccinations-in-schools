# frozen_string_literal: true

require_relative "../../app/lib/mavis_cli"

describe "mavis subteams create" do
  context "with valid arguments" do
    it "runs successfully" do
      given_a_team_exists
      when_i_run_the_command
      then_the_subteam_is_created
    end
  end

  private

  def given_a_team_exists
    @team = create(:team, workgroup: "my-team")
  end

  def command
    Dry::CLI.new(MavisCLI).call(
      arguments: %w[
        subteams
        create
        my-team
        --name
        MySubteam
        --email
        subteam@example.com
        --phone
        01234567890
      ]
    )
  end

  def when_i_run_the_command
    @output = capture_output { command }
  end

  def then_the_subteam_is_created
    subteam = @team.subteams.find_by(name: "MySubteam")
    expect(subteam.email).to eq("subteam@example.com")
    expect(subteam.phone).to eq("01234 567890")
  end
end
