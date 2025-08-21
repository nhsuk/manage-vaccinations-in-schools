# frozen_string_literal: true

require_relative "../../app/lib/mavis_cli"

describe "mavis sessions delegation" do
  context "with valid arguments" do
    it "runs successfully" do
      given_a_team_exists
      and_sessions_exist

      when_i_run_the_command
      then_the_team_sessions_are_updated
      and_the_non_team_sessions_are_left
    end
  end

  private

  def command
    Dry::CLI.new(MavisCLI).call(
      arguments: %w[sessions delegation team flu --psd --national-protocol]
    )
  end

  def given_a_team_exists
    @programmes = [create(:programme, :hpv), create(:programme, :flu)]
    @team = create(:team, workgroup: "team", programmes: @programmes)
  end

  def and_sessions_exist
    academic_year = AcademicYear.pending

    @team_hpv_session =
      create(
        :session,
        :unscheduled,
        team: @team,
        programmes: [@programmes.first],
        academic_year:
      )
    @non_team_hpv_session =
      create(
        :session,
        :unscheduled,
        programmes: [@programmes.first],
        academic_year:
      )
    @team_flu_session =
      create(
        :session,
        :unscheduled,
        team: @team,
        programmes: [@programmes.second],
        academic_year:
      )
    @non_team_flu_session =
      create(
        :session,
        :unscheduled,
        programmes: [@programmes.second],
        academic_year:
      )
  end

  def when_i_run_the_command
    @output = capture_output { command }
  end

  def then_the_team_sessions_are_updated
    expect(@team_flu_session.reload).to have_attributes(
      psd_enabled: true,
      national_protocol_enabled: true
    )

    expect(@team_hpv_session.reload).to have_attributes(
      psd_enabled: false,
      national_protocol_enabled: false
    )
  end

  def and_the_non_team_sessions_are_left
    expect(@non_team_flu_session.reload).to have_attributes(
      psd_enabled: false,
      national_protocol_enabled: false
    )

    expect(@non_team_hpv_session.reload).to have_attributes(
      psd_enabled: false,
      national_protocol_enabled: false
    )
  end
end
