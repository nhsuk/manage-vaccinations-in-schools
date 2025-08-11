# frozen_string_literal: true

describe "Access log" do
  around { |example| travel_to(Date.new(2025, 7, 31)) { example.run } }

  before { given_i_am_signed_in }

  scenario "View patient" do
    when_i_go_to_the_children
    and_i_go_to_a_patient
    then_i_am_recorded_in_the_access_log(controller: "patients")
  end

  scenario "View patient's activity log" do
    when_i_go_to_the_children
    and_i_go_to_a_patient
    and_i_click_on_activity_log
    then_i_am_recorded_in_the_access_log_twice(controller: "patients")
  end

  scenario "View patient in a session" do
    when_i_go_to_the_session
    and_i_go_to_a_patient
    then_i_am_recorded_in_the_access_log(controller: "patient_sessions")
  end

  scenario "View patient's activity log in a session" do
    when_i_go_to_the_session
    and_i_go_to_a_patient
    and_i_click_on_session_activity_and_notes
    then_i_am_recorded_in_the_access_log_twice(controller: "patient_sessions")
  end

  def given_i_am_signed_in
    programmes = [create(:programme, :hpv)]
    team = create(:team, :with_generic_clinic, :with_one_nurse, programmes:)

    @user = team.users.first

    @session = create(:session, team:, programmes:)
    @patient =
      create(
        :patient,
        :consent_given_triage_not_needed,
        year_group: 8,
        session: @session
      )

    sign_in @user
  end

  def when_i_go_to_the_children
    visit dashboard_path
    click_on "Children", match: :first
  end

  def when_i_go_to_the_session
    visit dashboard_path
    click_on "Programmes", match: :first
    click_on "HPV", match: :first

    within(".app-secondary-navigation") { click_on "Sessions" }

    click_on @session.location.name
    click_on "Consent"
  end

  def and_i_go_to_a_patient
    click_on @patient.full_name
  end

  def and_i_click_on_activity_log
    click_on "Activity log"
  end

  def and_i_click_on_session_activity_and_notes
    click_on "Session activity and notes"
  end

  def then_i_am_recorded_in_the_access_log(controller:)
    expect(AccessLogEntry.count).to eq(1)
    expect(AccessLogEntry.first).to have_attributes(
      user: @user,
      controller:,
      action: "show"
    )
  end

  def then_i_am_recorded_in_the_access_log_twice(controller:)
    expect(AccessLogEntry.count).to eq(2)
    expect(AccessLogEntry.first).to have_attributes(
      user: @user,
      controller:,
      action: "show"
    )
    expect(AccessLogEntry.second).to have_attributes(
      user: @user,
      controller:,
      action: "log"
    )
  end
end
