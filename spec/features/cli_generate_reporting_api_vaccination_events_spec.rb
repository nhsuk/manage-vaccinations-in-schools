# frozen_string_literal: true

require_relative "../../app/lib/mavis_cli"

describe "mavis generate vaccination-records" do
  it "generates Reporting API Vaccination Event records" do
    given_a_team_exists
    and_there_is_a_patient_in_a_session
    and_there_are_some_vaccination_records
    when_i_run_the_generate_reporting_api_vaccination_events_command
    then_reporting_api_vaccination_events_are_created
  end

  it "updates existing Reporting API Vaccination Event records" do
    given_a_team_exists
    and_there_is_a_patient_in_a_session
    and_there_are_some_vaccination_records
    and_the_vaccination_records_already_have_reporting_api_vaccination_events
    when_i_run_the_generate_reporting_api_vaccination_events_command
    then_it_does_not_generate_new_vaccination_event_records
    and_it_updates_the_existing_vaccination_event_records
  end

  it "only affects Vaccination Records created after the given min_datetime" do
    given_a_team_exists
    and_there_is_a_patient_in_a_session
    and_there_are_some_vaccination_records
    when_i_run_the_generate_reporting_api_vaccination_events_command_with_a_min_datetime
    then_reporting_api_vaccination_event_records_are_only_created_for_vaccination_records_created_after_the_given_min_datetime
  end

  def given_a_team_exists
    @programme = Programme.find_by(type: "hpv") || create(:programme, type: "hpv")
    @team = create(:team, programmes: [@programme])
  end

  def nurse
    User.find_by(fallback_role: :nurse) || create(:nurse)
  end

  def and_there_is_a_patient_in_a_session
    subteam = create(:subteam, team: @team)
    location = create(:generic_clinic, subteam:)
    @session =
      create(:session, team: @team, programmes: [@programme], location:)
    parent = create(:parent)
    @patient = create(
      :patient,
      :consent_given_triage_not_needed,
      team: @team,
      session: @session,
      programmes: [@programme],
      parents: [parent]
    )
    @other_patient = create(
      :patient,
      :consent_given_triage_not_needed,
      team: @team,
      session: @session,
      programmes: [@programme],
      parents: [parent]
    )
  end

  def and_there_are_some_vaccination_records
    @vr1 = create(
      :vaccination_record,
      patient: @patient,
      session: @session,
      location: @session.location,
      performed_by: nurse,
      programme: @programme,
      created_at: Time.current - 1.day,
      updated_at: Time.current - 1.day,
    )
    @vr2 = create(
      :vaccination_record,
      patient: @other_patient,
      session: @session,
      location: @session.location,
      performed_by: nurse,
      programme: @programme,
      created_at: Time.current - 4.hours,
      updated_at: Time.current - 4.hours,
    )
  end

  def and_the_vaccination_records_already_have_reporting_api_vaccination_events
    VaccinationRecord.all.each{ |vr| vr.create_or_update_reporting_api_vaccination_event }
  end

  def when_i_run_the_generate_reporting_api_vaccination_events_command
    @vaccination_events_count_before = ReportingAPI::VaccinationEvent.count

    Dry::CLI.new(MavisCLI).call(
      arguments: [
        "reporting-api-vaccination-events",
        "regenerate",
      ]
    )
  end

  def when_i_run_the_generate_reporting_api_vaccination_events_command_with_a_min_datetime
    @vaccination_events_count_before = ReportingAPI::VaccinationEvent.count

    Dry::CLI.new(MavisCLI).call(
      arguments: [
        "reporting-api-vaccination-events",
        "regenerate",
        "--min-datetime",
        "#{(Time.current - 8.hours).iso8601}"
      ]
    )
  end

  def then_reporting_api_vaccination_events_are_created
    expect(
      ReportingAPI::VaccinationEvent.count
    ).to be > @vaccination_events_count_before
  end

  def then_it_does_not_generate_new_vaccination_event_records
    expect(
      ReportingAPI::VaccinationEvent.count
    ).to eq @vaccination_events_count_before
  end

  def and_it_updates_the_existing_vaccination_event_records
    expect( ReportingAPI::VaccinationEvent.pluck(:updated_at) ).to all be_within(1.second).of(Time.current)
  end

end
