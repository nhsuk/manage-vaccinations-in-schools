# frozen_string_literal: true

require_relative "../../app/lib/mavis_cli"

describe "mavis stats vaccinations" do
  context "when comprehensive vaccination data exists" do
    it "displays statistics and handles various filters and formats" do
      given_comprehensive_vaccination_data_exists

      when_i_run_the_command
      then_i_see_counts_grouped_by_programme_and_outcome

      when_i_run_the_command_with_ods_code(@target_organisation.ods_code)
      then_i_see_counts_for_target_organisation_only

      when_i_run_the_command_with_team_filter(@target_team.name)
      then_i_see_counts_for_target_team_only

      when_i_run_the_command_with_programme_filter("flu")
      then_i_see_counts_for_flu_programme_only

      when_i_run_the_command_with_csv
      then_i_see_csv_output
    end
  end

  private

  def command(args = [])
    Dry::CLI.new(MavisCLI).call(arguments: ["stats", "vaccinations", *args])
  end

  def given_comprehensive_vaccination_data_exists
    @programme_flu = create(:programme, type: "flu")
    @programme_hpv = create(:programme, type: "hpv")
    @programme_menacwy = create(:programme, type: "menacwy")

    @target_organisation = create(:organisation, ods_code: "TARGET123")
    @target_team =
      create(:team, organisation: @target_organisation, name: "Team Alpha")
    target_team2 =
      create(:team, organisation: @target_organisation, name: "Team Beta")

    other_organisation = create(:organisation, ods_code: "OTHER456")
    other_team =
      create(:team, organisation: other_organisation, name: "TEAM999")

    target_patient1 = create(:patient, team: @target_team)
    target_patient2 = create(:patient, team: target_team2)
    other_patient = create(:patient, team: other_team)

    target_session1 =
      create(
        :session,
        team: @target_team,
        programmes: [@programme_flu, @programme_hpv]
      )
    target_session2 =
      create(
        :session,
        team: target_team2,
        programmes: [@programme_flu, @programme_menacwy]
      )
    other_session =
      create(:session, team: other_team, programmes: [@programme_flu])

    create(
      :vaccination_record,
      patient: target_patient1,
      programme: @programme_flu,
      outcome: "administered",
      session: target_session1
    )
    create(
      :vaccination_record,
      patient: target_patient1,
      programme: @programme_flu,
      outcome: "refused",
      session: target_session1
    )
    create(
      :vaccination_record,
      patient: target_patient1,
      programme: @programme_hpv,
      outcome: "administered",
      session: target_session1
    )

    create(
      :vaccination_record,
      patient: target_patient2,
      programme: @programme_flu,
      outcome: "administered",
      session: target_session2
    )
    create(
      :vaccination_record,
      patient: target_patient2,
      programme: @programme_menacwy,
      outcome: "absent_from_session",
      session: target_session2
    )

    create(
      :vaccination_record,
      patient: other_patient,
      programme: @programme_flu,
      outcome: "administered",
      session: other_session
    )
    create(
      :vaccination_record,
      patient: other_patient,
      programme: @programme_flu,
      outcome: "contraindications",
      session: other_session
    )
  end

  def when_i_run_the_command
    @output = capture_output { command }
  end

  def when_i_run_the_command_with_csv
    @output = capture_output { command(%w[--format csv]) }
  end

  def when_i_run_the_command_with_invalid_organisation
    @output = capture_error { command(%w[--ods_code INVALID_ODS]) }
  end

  def when_i_run_the_command_with_ods_code(ods_code)
    @output = capture_output { command(["--ods_code", ods_code]) }
  end

  def when_i_run_the_command_with_team_filter(team_ods_code)
    @output = capture_output { command(["--team_name", team_ods_code]) }
  end

  def when_i_run_the_command_with_programme_filter(programme)
    @output = capture_output { command(["--programme", programme]) }
  end

  def when_i_run_the_command_with_invalid_programme
    @output = capture_error { command(%w[--programme doesnotexist]) }
  end

  def then_i_see_empty_results
    expect(@output).to include("Grand Total: 0").or include("{}").or include(
                "No vaccination records found"
              )
  end

  def then_i_see_empty_csv_results
    expect(@output).to include("Programme,Outcome,Count")
    expect(
      @output.lines.count do |l|
        l.strip != "" && !l.include?("Programme,Outcome,Count")
      end
    ).to eq(0)
  end

  def then_an_organisation_not_found_error_message_is_displayed
    expect(@output).to include(
      "Could not find organisation with ODS code 'INVALID_ODS'"
    )
  end

  def then_i_get_an_error_message
    expect(@output).to include(
      'was called with arguments "--programme doesnotexist"'
    )
  end

  def then_i_see_counts_grouped_by_programme_and_outcome
    expect(@output).to include("flu")
    expect(@output).to include("hpv")
    expect(@output).to include("menacwy")
    expect(@output).to match(/administered.*3/)
    expect(@output).to match(/refused.*1/)
    expect(@output).to match(/absent_from_session.*1/)
    expect(@output).to match(/contraindication.*1/)
    expect(@output).to match(/Grand Total: 7/)
  end

  def then_i_see_counts_for_target_organisation_only
    expect(@output).to include("flu")
    expect(@output).to include("hpv")
    expect(@output).to include("menacwy")
    expect(@output).to match(/administered.*2/)
    expect(@output).to match(/refused.*1/)
    expect(@output).to match(/absent_from_session.*1/)
    expect(@output).not_to match(/contraindication/)
    expect(@output).to match(/Grand Total: 5/)
    expect(@output).to include(
      "Filtering by organisation: #{@target_organisation.ods_code}"
    )
  end

  def then_i_see_counts_for_target_team_only
    expect(@output).to include("flu")
    expect(@output).to include("hpv")
    expect(@output).not_to include("menacwy")
    expect(@output).to match(/administered.*1/)
    expect(@output).to match(/refused.*1/)
    expect(@output).not_to match(/absent_from_session/)
    expect(@output).to match(/Grand Total: 3/)
    expect(@output).to include("Filtering by team: #{@target_team.name}")
  end

  def then_i_see_counts_for_flu_programme_only
    expect(@output).to include("flu")
    expect(@output).not_to include("hpv")
    expect(@output).not_to include("menacwy")
    expect(@output).to match(/administered.*3/)
    expect(@output).to match(/refused.*1/)
    expect(@output).to match(/contraindication.*1/)
    expect(@output).not_to match(/absent_from_session/)
    expect(@output).to match(/Grand Total: 5/)
  end

  def then_i_see_csv_output
    expect(@output).to include("Programme,Outcome,Count")
    expect(@output).to include("flu,administered,")
    expect(@output).to include("hpv,administered,")
    expect(@output).to include("flu,refused,")
    expect(@output.lines.count { |l| l =~ /flu|hpv|menacwy/ }).to be > 0
  end
end
