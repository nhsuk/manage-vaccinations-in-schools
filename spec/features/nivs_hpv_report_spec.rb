# frozen_string_literal: true

require "rails_helper"

describe "NIVS HPV report" do
  scenario "User downloads the NIVS HPV report" do
    given_i_am_signed_in
    and_vaccinations_have_happened_in_my_teams_hpv_campaign
    when_i_go_to_the_reports_page
    and_i_download_the_nivs_hpv_report
    then_i_should_see_all_the_administered_vaccinations_from_my_teams_hpv_campaign
  end

  def given_i_am_signed_in
    @team = create(:team, :with_one_nurse, :with_one_location)
    sign_in @team.users.first
  end

  def and_vaccinations_have_happened_in_my_teams_hpv_campaign
    campaign = create(:campaign, :hpv, team: @team)
    session = create(:session, campaign:, location: @team.locations.first)
    create_list(:patient_session, 5, :consent_given_triage_not_needed, session:)
    session
      .patient_sessions
      .first(3)
      .each { |patient_session| create(:vaccination_record, patient_session:) }
    create(
      :vaccination_record,
      :unadministered,
      patient_session: session.patient_sessions[3]
    )
    create(
      :vaccination_record,
      :unrecorded,
      patient_session: session.patient_sessions.last,
      user: @team.users.first
    )
    @patient_sessions = session.patient_sessions
  end

  def when_i_go_to_the_reports_page
    visit "/reports"

    expect(page).to have_css("h1", text: "Reports")
  end

  def and_i_download_the_nivs_hpv_report
    click_on "Download data (CSV)"
  end

  def then_i_should_see_all_the_administered_vaccinations_from_my_teams_hpv_campaign
    expect(page.response_headers["Content-Type"]).to eq("text/csv")
    expect(page.response_headers["Content-Disposition"]).to include(
      "NIVS-HPV-report-MAVIS.csv"
    )

    csv = CSV.parse(page.body, headers: true)
    expect(csv.size).to eq(3)

    @patient_sessions
      .first(3)
      .each do |patient_session|
        expect(page.body).to include(patient_session.patient.nhs_number)
        expect(page.body).to include(patient_session.patient.first_name)
        expect(page.body).to include(patient_session.patient.last_name)
      end
  end
end
