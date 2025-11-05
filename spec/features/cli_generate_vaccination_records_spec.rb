# frozen_string_literal: true

require_relative "../../app/lib/mavis_cli"

describe "mavis generate vaccination-records" do
  it "generates vaccination records" do
    given_an_team_exists
    and_there_is_a_patient_in_a_session
    when_i_run_the_generate_vaccination_records_command
    then_vaccination_administered_records_are_created
  end

  def given_an_team_exists
    @programme = CachedProgramme.hpv
    @team = create(:team, programmes: [@programme])
  end

  def and_there_is_a_patient_in_a_session
    subteam = create(:subteam, team: @team)
    location = create(:generic_clinic, subteam:)
    @session =
      create(:session, team: @team, programmes: [@programme], location:)
    parent = create(:parent)
    create(
      :patient,
      :consent_given_triage_not_needed,
      team: @team,
      session: @session,
      programmes: [@programme],
      parents: [parent]
    )
  end

  def when_i_run_the_generate_vaccination_records_command
    @vaccination_records_count_before = @team.vaccination_records.count

    Dry::CLI.new(MavisCLI).call(
      arguments: [
        "generate",
        "vaccination-records",
        "-w",
        @team.workgroup,
        "-p",
        @programme.type,
        "-s",
        @session.id.to_s,
        "-A",
        "1"
      ]
    )
  end

  def then_vaccination_administered_records_are_created
    expect(
      @team.reload.vaccination_records.count
    ).to eq @vaccination_records_count_before + 1

    expect(
      @team
        .reload
        .patients
        .has_vaccination_status(
          :vaccinated,
          programme: @programme,
          academic_year: AcademicYear.current
        )
        .count
    ).to eq 1
  end
end
