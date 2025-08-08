# frozen_string_literal: true

require_relative "../../app/lib/mavis_cli"

describe "mavis stats consents-by-school" do
  context "when organisation has consent data" do
    it "displays consent statistics and handles filtering" do
      given_organisation_has_consent_data

      when_i_run_the_command
      then_i_see_consent_statistics_for_all_programmes

      when_i_run_the_command_with_flu_programme
      then_i_see_consent_statistics_for_flu_only

      when_i_run_the_command_with_previous_academic_year
      then_i_see_consent_statistics_for_previous_year_only

      when_i_run_the_command_with_team_filtering
      then_i_see_consent_statistics_for_team_only
    end
  end

  private

  def command(args = [])
    Dry::CLI.new(MavisCLI).call(
      arguments: ["stats", "consents-by-school", *args]
    )
  end

  def given_organisation_has_consent_data
    @organisation = create(:organisation, ods_code: "TEST003")
    programme_flu = create(:programme, type: "flu")
    programme_hpv = create(:programme, type: "hpv")

    @team_a =
      create(:team, organisation: @organisation, name: "Immunisation North")
    @team_b =
      create(:team, organisation: @organisation, name: "Immunisation South")

    @team_a.programmes << [programme_flu, programme_hpv]
    @team_b.programmes << [programme_flu, programme_hpv]

    school1 = create(:school, name: "Primary School", team: @team_a)
    school2 = create(:school, name: "Secondary School", team: @team_b)

    session1 =
      create(
        :session,
        team: @team_a,
        location: school1,
        programmes: [programme_flu],
        academic_year: AcademicYear.current,
        send_consent_requests_at: 10.days.ago
      )

    session2 =
      create(
        :session,
        team: @team_b,
        location: school2,
        programmes: [programme_hpv],
        academic_year: AcademicYear.current,
        send_consent_requests_at: 8.days.ago
      )

    session3 =
      create(
        :session,
        team: @team_a,
        location: school1,
        programmes: [programme_flu, programme_hpv],
        academic_year: AcademicYear.current,
        send_consent_requests_at: 12.days.ago
      )

    session_prev_year =
      create(
        :session,
        team: @team_a,
        location: school1,
        programmes: [programme_flu],
        academic_year: 2023,
        date: Date.new(2024, 3, 15),
        send_consent_requests_at: Date.new(2024, 3, 1)
      )

    patient1 = create(:patient, team: @team_a)
    patient2 = create(:patient, team: @team_b)
    patient3 = create(:patient, team: @team_a)
    patient_prev = create(:patient, team: @team_a)

    create(:patient_session, session: session1, patient: patient1)
    create(:patient_session, session: session2, patient: patient2)
    create(:patient_session, session: session3, patient: patient3)
    create(
      :patient_session,
      :consent_given_triage_not_needed,
      session: session_prev_year,
      patient: patient_prev
    )

    create(
      :consent,
      :given,
      patient: patient1,
      programme: programme_flu,
      submitted_at: 8.days.ago,
      created_at: 8.days.ago
    )

    create(
      :consent,
      :refused,
      patient: patient2,
      programme: programme_hpv,
      submitted_at: 6.days.ago,
      created_at: 6.days.ago
    )

    create(
      :consent,
      :given,
      patient: patient3,
      programme: programme_flu,
      submitted_at: 10.days.ago,
      created_at: 10.days.ago
    )

    create(
      :consent,
      :given,
      patient: patient_prev,
      programme: programme_flu,
      submitted_at: Date.new(2024, 3, 5),
      created_at: Date.new(2024, 3, 5)
    )
  end

  def when_i_run_the_command
    @output = capture_output { command(["--ods_code", @organisation.ods_code]) }
  end

  def when_i_run_the_command_with_flu_programme
    @output =
      capture_output do
        command(["--ods_code", @organisation.ods_code, "--programme", "flu"])
      end
  end

  def when_i_run_the_command_with_previous_academic_year
    previous_year = AcademicYear.current - 1
    @output =
      capture_output do
        command(
          [
            "--ods_code",
            @organisation.ods_code,
            "--academic_year",
            previous_year.to_s
          ]
        )
      end
  end

  def when_i_run_the_command_with_team_filtering
    @output =
      capture_output do
        command(
          [
            "--ods_code",
            @organisation.ods_code,
            "--team_name",
            "Immunisation North"
          ]
        )
      end
  end

  def then_i_see_consent_statistics_for_all_programmes
    expect(@output).to include("--- Consent Responses by Date ---")
    expect(@output).to include(
      "--- Consent Responses by Days Since Request ---"
    )
    expect(@output).to include("Primary School")
    expect(@output).to include("Secondary School")
    expect(@output).to include("Cohort")
    expect(@output).to match(/\d{4}-\d{2}-\d{2}/)
  end

  def then_i_see_consent_statistics_for_flu_only
    expect(@output).to include("--- Consent Responses by Date ---")
    expect(@output).to include(
      "--- Consent Responses by Days Since Request ---"
    )
    expect(@output).to include("Primary School")
    expect(@output).to include("Cohort")
    expect(@output).to include("Date consent requests sent")
    expect(@output).to match(/\d{4}-\d{2}-\d{2}/)
  end

  def then_i_see_consent_statistics_for_previous_year_only
    expect(@output).to include("--- Consent Responses by Date ---")
    expect(@output).to include(
      "--- Consent Responses by Days Since Request ---"
    )

    current_year = Date.current.year.to_s
    prev_year_date = Date.new(2024, 3, 1).strftime("%Y-%m-%d")

    expect(@output).not_to include(current_year)
    expect(@output).to include(prev_year_date)
  end

  def then_i_see_consent_statistics_for_team_only
    expect(@output).to include("Filtering by team: Immunisation North")
    expect(@output).to include("Primary School")
    expect(@output).not_to include("Secondary School")
    expect(@output).to include("Cohort")
    expect(@output).to include("--- Consent Responses by Date ---")
    expect(@output).to include(
      "--- Consent Responses by Days Since Request ---"
    )
  end
end
