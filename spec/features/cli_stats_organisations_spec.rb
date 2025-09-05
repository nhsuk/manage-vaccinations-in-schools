# frozen_string_literal: true

require_relative "../../app/lib/mavis_cli"

describe "mavis stats organisations" do
  context "when organisation has complete data" do
    before { given_organisation_has_complete_data_with_filters }

    it "displays comprehensive statistics in table format by default" do
      when_i_run_the_command
      then_i_see_comprehensive_statistics
    end

    it "filters by programme" do
      when_i_run_the_command_with_programme_filter("flu")
      then_i_see_only_filtered_programme_statistics
    end

    it "filters by academic year" do
      when_i_run_the_command_with_academic_year_filter
      then_i_see_only_filtered_academic_year_statistics
    end

    it "filters by team" do
      when_i_run_the_command_with_team_filter("North Team")
      then_i_see_only_team_filtered_statistics
    end

    it "outputs JSON format" do
      when_i_run_the_command_with_json
      then_i_see_json_output
    end
  end

  context "when handling invalid input" do
    before { @organisation = create(:organisation, ods_code: "TEST002") }

    it "shows error for invalid organisation" do
      when_i_run_the_command_with_invalid_organisation
      then_an_organisation_not_found_error_message_is_displayed
    end

    it "shows error for invalid team" do
      when_i_run_the_command_with_invalid_team
      then_a_team_not_found_error_message_is_displayed
    end
  end

  context "when organisation has no data" do
    before { given_organisation_has_no_data }

    it "shows empty results in table format" do
      when_i_run_the_command
      then_i_see_empty_results
    end

    it "shows empty results in JSON format" do
      when_i_run_the_command_with_json
      then_i_see_empty_json_results
    end
  end

  private

  def command(args = [])
    Dry::CLI.new(MavisCLI).call(arguments: ["stats", "organisations", *args])
  end

  def given_organisation_has_complete_data_with_filters
    @organisation = create(:organisation, ods_code: "TEST002")
    programme_flu = create(:programme, type: "flu")
    programme_hpv = create(:programme, type: "hpv")
    programme_menacwy = create(:programme, type: "menacwy")

    @team_a = create(:team, organisation: @organisation, name: "North Team")
    @team_b = create(:team, organisation: @organisation, name: "South Team")

    @team_a.programmes << [programme_flu, programme_hpv, programme_menacwy]
    @team_b.programmes << [programme_flu, programme_hpv, programme_menacwy]

    school1 =
      create(
        :school,
        name: "Hogwarts",
        team: @team_a,
        programmes: [programme_flu]
      )
    school2 =
      create(
        :school,
        name: "East High",
        team: @team_b,
        programmes: [programme_hpv]
      )

    session1 =
      create(
        :session,
        team: @team_a,
        location: school1,
        programmes: [programme_flu]
      )
    session2 =
      create(
        :session,
        team: @team_b,
        location: school2,
        programmes: [programme_hpv]
      )

    session_last_year =
      create(
        :session,
        team: @team_a,
        academic_year: AcademicYear.current - 1,
        programmes: [programme_flu],
        date: (AcademicYear.current - 1).to_academic_year_date_range.end
      )

    patient_year_8 = create(:patient, team: @team_a, year_group: 8)
    patient_year_9 = create(:patient, team: @team_a, year_group: 9)
    patient_year_10 = create(:patient, team: @team_b, year_group: 10)
    patient_year_11 = create(:patient, team: @team_a, year_group: 11)

    create(
      :patient_session,
      :consent_given_triage_not_needed,
      :vaccinated,
      session: session1,
      patient: patient_year_8
    )
    create(
      :patient_session,
      :consent_refused,
      :vaccinated,
      session: session1,
      patient: patient_year_9
    )
    create(
      :patient_session,
      :consent_given_triage_not_needed,
      session: session2,
      patient: patient_year_10
    )
    create(
      :patient_session,
      :consent_no_response,
      session: session1,
      patient: patient_year_11
    )

    create(
      :patient_session,
      :consent_refused,
      session: session_last_year,
      patient: patient_year_8
    )

    create(
      :patient_session,
      :consent_given_triage_not_needed,
      patient: patient_year_9,
      programmes: [programme_flu, programme_hpv, programme_menacwy]
    )

    create(
      :consent_notification,
      :request,
      patient: patient_year_8,
      session: session1
    )
    create(
      :consent_notification,
      :initial_reminder,
      patient: patient_year_8,
      session: session1
    )
    create(
      :consent_notification,
      :request,
      patient: patient_year_9,
      session: session1
    )
  end

  def given_organisation_has_no_data
    @organisation = create(:organisation, ods_code: "EMPTY001")
    create(:team, organisation: @organisation, name: "Empty Team")
  end

  def when_i_run_the_command
    @output = capture_output { command(["--ods_code", @organisation.ods_code]) }
  end

  def when_i_run_the_command_with_programme_filter(programme)
    @output =
      capture_output do
        command(
          ["--ods_code", @organisation.ods_code, "--programme", programme]
        )
      end
  end

  def when_i_run_the_command_with_academic_year_filter
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

  def when_i_run_the_command_with_team_filter(team_name)
    @output =
      capture_output do
        command(
          ["--ods_code", @organisation.ods_code, "--team_name", team_name]
        )
      end
  end

  def when_i_run_the_command_with_json
    @output =
      capture_output do
        command(["--ods_code", @organisation.ods_code, "--format", "json"])
      end
  end

  def when_i_run_the_command_with_invalid_organisation
    @output = capture_error { command(%w[--ods_code INVALID_ODS]) }
  end

  def when_i_run_the_command_with_invalid_team
    @output =
      capture_error do
        command(
          ["--ods_code", @organisation.ods_code, "--team_name", "INVALID_TEAM"]
        )
      end
  end

  def then_i_see_comprehensive_statistics
    expect(@output).to include(@team_a.name)
    expect(@output).to include(@team_b.name)
    expect(@output).to include(@organisation.ods_code)
    expect(@output).to include("Programme: flu")
    expect(@output).to include("Programme: hpv")
    expect(@output).to include("Programme: menacwy")
    expect(@output).to include("Total eligible patients:")
    expect(@output).to include("Year 8: 1")
    expect(@output).to include("Year 9: 1")
    expect(@output).to include("Year 10: 1")
    expect(@output).to include("Year 11: 1")
    expect(@output).to include("Total schools:")
    expect(@output).to include("Total consent responses received:")
    expect(@output).to include("Patients with status 'given':")
    expect(@output).to include("Patients with status 'refused':")
    expect(@output).to include("Coverage:")
    expect(@output).to include("Vaccinated in Mavis:")
    expect(@output).to include("Patients with no response:")
    expect(@output).to include("Schools involved in consent notifications:")
    expect(@output).to include("Patients who received consent notifications:")
    expect(@output).to include("of these, consent requests:")
    expect(@output).to include("of these, consent reminders:")
  end

  def then_i_see_only_filtered_programme_statistics
    expect(@output).to include("Programme: flu")
    expect(@output).not_to include("Programme: hpv")
    expect(@output).not_to include("Programme: menacwy")
    expect(@output).to include("(flu programme)")
  end

  def then_i_see_only_filtered_academic_year_statistics
    previous_year = AcademicYear.current - 1
    date_range = previous_year.to_academic_year_date_range
    start_date = date_range.first.strftime("%-d %B %Y")
    end_date = date_range.last.strftime("%-d %B %Y")

    expect(@output).to include("from #{start_date} to #{end_date}")
  end

  def then_i_see_only_team_filtered_statistics
    expect(@output).to include("Filtering by team: North Team")
    expect(@output).not_to include("Year 10:")
  end

  def then_i_see_json_output
    filtered_output =
      @output.lines.reject { |line| line.strip.start_with?("Filtering") }.join
    json_data = JSON.parse(filtered_output)
    expect(json_data["ods_code"]).to eq(@organisation.ods_code)
    expect(json_data["programme_stats"]).to be_an(Array)
    expect(json_data["programme_stats"].size).to be > 0
  end

  def then_i_see_empty_results
    expect(@output).not_to include("Total eligible patients:")
    expect(@output).not_to include("Total schools:")
    expect(@output).not_to include("Coverage:")
  end

  def then_i_see_empty_json_results
    filtered_output =
      @output.lines.reject { |line| line.strip.start_with?("Filtering") }.join
    json_data = JSON.parse(filtered_output)
    expect(json_data["ods_code"]).to eq(@organisation.ods_code)
    expect(json_data["programme_stats"]).to be_empty
  end

  def then_an_organisation_not_found_error_message_is_displayed
    expect(@output).to include(
      "Could not find organisation with ODS code 'INVALID_ODS'"
    )
  end

  def then_a_team_not_found_error_message_is_displayed
    expect(@output).to include(
      "Could not find team 'INVALID_TEAM' for organisation '#{@organisation.ods_code}'"
    )
  end
end
