# frozen_string_literal: true

require_relative "../../app/lib/mavis_cli"

describe "mavis users create", :local_users do
  context "with valid arguments" do
    it "runs successfully" do
      given_a_team_exists
      when_i_run_the_command
      then_the_user_is_created
    end
  end

  private

  def given_a_team_exists
    @team = create(:team, workgroup: "my-team")
  end

  def command
    Dry::CLI.new(MavisCLI).call(
      arguments: %w[
        users
        create
        my-team
        --email
        user@example.com
        --password
        password123
        --given-name
        First
        --family-name
        Last
      ]
    )
  end

  def when_i_run_the_command
    @output = capture_output { command }
  end

  def then_the_user_is_created
    user = @team.users.find_by(email: "user@example.com")
    expect(user).to be_fallback_role_nurse
    expect(user.given_name).to eq("First")
    expect(user.family_name).to eq("Last")
  end
end
