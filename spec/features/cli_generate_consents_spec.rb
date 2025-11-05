# frozen_string_literal: true

require_relative "../../app/lib/mavis_cli"

describe "mavis generate consents" do
  it "generates consents" do
    given_an_team_exists
    and_there_are_three_patients_in_a_session
    when_i_run_the_generate_consents_command
    then_consents_are_created_with_the_given_statuses
  end

  def given_an_team_exists
    @team = create(:team)
    @programme = create(:programme, :hpv)
  end

  def and_there_are_three_patients_in_a_session
    @session = create(:session, team: @team, programmes: [@programme])
    parent = create(:parent)
    create_list(
      :patient,
      3,
      team: @team,
      session: @session,
      programmes: [@programme],
      parents: [parent]
    )
  end

  def when_i_run_the_generate_consents_command
    @consent_count_before = @team.consents.count

    Dry::CLI.new(MavisCLI).call(
      arguments: [
        "generate",
        "consents",
        "-w",
        @team.workgroup,
        "-p",
        @programme.type,
        "-s",
        @session.id.to_s,
        "-g",
        "1",
        "-N",
        "1",
        "-r",
        "1"
      ]
    )
  end

  def then_consents_are_created_with_the_given_statuses
    expect(@team.consents.count).to eq @consent_count_before + 3

    expect(
      @team
        .patients
        .has_consent_status(
          :given,
          programme: @programme,
          academic_year: AcademicYear.current
        )
        .has_triage_status(
          :not_required,
          programme: @programme,
          academic_year: AcademicYear.current
        )
        .count
    ).to eq 1
  end
end
