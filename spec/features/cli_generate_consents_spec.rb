# frozen_string_literal: true

require_relative "../../app/lib/mavis_cli"

describe "mavis generate consents" do
  scenario "generating consents for a specific session" do
    given_a_team_exists
    and_there_are_three_patients_in_a_session
    when_i_run_the_generate_consents_command_for_that_session
    then_consents_are_created_within_the_session
  end

  scenario "generating consents for any session" do
    given_a_team_exists
    and_there_are_two_sessions_with_two_patients
    when_i_generate_one_of_each_consents_across_all_sessions
    then_one_of_each_consent_is_created_across_sessions
  end

  def given_a_team_exists
    @team = create(:team)
    @programme = Programme.hpv
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

  def and_there_are_two_sessions_with_two_patients
    2.times.map do
      session = create(:session, team: @team, programmes: [@programme])
      parent = create(:parent)
      create_list(
        :patient,
        2,
        team: @team,
        session:,
        programmes: [@programme],
        parents: [parent]
      )
    end
  end

  def when_i_run_the_generate_consents_command_for_that_session
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

  def when_i_generate_one_of_each_consents_across_all_sessions
    Dry::CLI.new(MavisCLI).call(
      arguments: [
        "generate",
        "consents",
        "-w",
        @team.workgroup,
        "-p",
        @programme.type,
        "-g",
        "1",
        "-N",
        "1",
        "-r",
        "1"
      ]
    )
  end

  def then_consents_are_created_within_the_session
    expect(
      @session.patients.flat_map(&:consents).count
    ).to eq @consent_count_before + 3
  end

  def then_one_of_each_consent_is_created_across_sessions
    expect(@team.consents.count).to eq 3

    expect(
      @team
        .patients
        .has_programme_status(
          "due",
          programme: @programme,
          academic_year: AcademicYear.current
        )
        .count
    ).to eq 1
    expect(
      @team
        .patients
        .has_programme_status(
          "due",
          programme: @programme,
          academic_year: AcademicYear.current
        )
        .count
    ).to eq 1
    expect(
      @team
        .patients
        .has_consent_status(
          :refused,
          programme: @programme,
          academic_year: AcademicYear.current
        )
        .count
    ).to eq 1
  end
end
