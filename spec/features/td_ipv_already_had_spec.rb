# frozen_string_literal: true

describe "Td/IPV" do
  around { |example| travel_to(Date.new(2025, 7, 1)) { example.run } }

  scenario "record a patient as already vaccinated outside the school session" do
    given_a_td_ipv_programme_with_a_session(clinic: false)
    and_a_patient_is_in_the_session
    and_the_patient_doesnt_need_triage

    when_i_go_the_session
    then_i_see_one_patient_needing_consent
    and_i_click_on_the_patient
    then_i_see_the_patient_needs_consent

    when_i_click_record_as_already_vaccinated
    when_i_click_back
    then_i_see_the_patient_session_page

    when_i_click_record_as_already_vaccinated
    and_i_confirm_the_details
    then_i_see_the_patient_is_already_vaccinated
    and_the_patient_no_longer_appears_in_consent
    and_the_consent_requests_are_sent
    then_the_parent_doesnt_receive_a_consent_request
  end

  scenario "record a patient as already vaccinated outside the clinic session" do
    given_a_td_ipv_programme_with_a_session(clinic: true)
    and_a_patient_is_in_the_session
    and_the_patient_doesnt_need_triage

    when_i_go_the_session
    then_i_see_one_patient_needing_consent
    and_i_click_on_the_patient
    then_i_see_the_patient_needs_consent

    when_i_click_record_as_already_vaccinated
    and_i_confirm_the_details
    then_i_see_the_patient_is_already_vaccinated
    and_the_patient_no_longer_appears_in_consent
    and_the_consent_requests_are_sent
    then_the_parent_doesnt_receive_a_consent_request
  end

  scenario "record a patient needing triage as already vaccinated outside the school session" do
    given_a_td_ipv_programme_with_a_session(clinic: false)
    and_a_patient_is_in_the_session
    and_the_patient_needs_triage

    when_i_go_the_session
    then_i_see_one_patient_needing_triage
    and_i_click_on_the_patient
    then_i_see_the_patient_needs_triage

    when_i_click_record_as_already_vaccinated
    and_i_confirm_the_details
    then_i_see_the_patient_is_already_vaccinated
    and_the_patient_no_longer_appears_in_consent
    and_i_click_on_triage
    then_i_see_the_patient_doesnt_need_triage
  end

  scenario "can't record as already vaccinated as a medical secretary" do
    given_a_td_ipv_programme_with_a_session(clinic: false)
    and_a_patient_is_in_the_session
    and_the_patient_doesnt_need_triage

    when_i_go_the_session_as_an_admin
    then_i_see_one_patient_needing_consent
    and_i_click_on_the_patient
    then_i_see_the_patient_needs_consent
    and_i_cannot_record_the_patient_as_already_vaccinated
  end

  def given_a_td_ipv_programme_with_a_session(clinic:)
    @programme = create(:programme, :td_ipv)
    programmes = [@programme]

    team = create(:team, programmes:)
    @nurse = create(:nurse, teams: [team])

    location =
      (
        if clinic
          create(:generic_clinic, team:)
        else
          create(:school, :secondary, urn: 123_456, team:)
        end
      )

    create(:community_clinic, name: "Waterloo Hospital", team:)

    @session =
      create(
        :session,
        date: 1.week.from_now.to_date,
        team:,
        programmes:,
        location:
      )
  end

  def and_a_patient_is_in_the_session
    @patient = create(:patient, session: @session)
  end

  def and_the_patient_doesnt_need_triage
    create(:patient_consent_status, patient: @patient, programme: @programme)
    create(
      :patient_triage_status,
      :not_required,
      patient: @patient,
      programme: @programme
    )
  end

  def and_the_patient_needs_triage
    create(
      :consent,
      :given,
      :needing_triage,
      patient: @patient,
      programme: @programme
    )
    create(
      :patient_consent_status,
      :given,
      patient: @patient,
      programme: @programme
    )
    create(
      :patient_triage_status,
      :required,
      patient: @patient,
      programme: @programme
    )
  end

  def when_i_go_the_session
    sign_in @nurse
    visit dashboard_path
    click_on "Sessions", match: :first
    choose "Scheduled"
    click_on "Update results"
    click_on @session.location.name
  end

  def when_i_go_the_session_as_an_admin
    sign_in @nurse, role: :medical_secretary
    visit dashboard_path
    click_on "Sessions", match: :first
    choose "Scheduled"
    click_on "Update results"
    click_on @session.location.name
  end

  def then_i_see_one_patient_needing_consent
    click_on "Consent"

    check "No response"
    click_on "Update results"

    expect(page).to have_content("Showing 1 to 1 of 1 children")
  end

  def then_i_see_one_patient_needing_triage
    click_on "Triage"

    choose "Needs triage"
    click_on "Update results"

    expect(page).to have_content("Showing 1 to 1 of 1 children")
  end

  def and_i_click_on_the_patient
    click_on @patient.full_name
  end

  def then_i_see_the_patient_needs_consent
    expect(page).to have_content("No response")
  end

  def then_i_see_the_patient_needs_triage
    expect(page).to have_content("Needs triage")
  end

  def when_i_click_record_as_already_vaccinated
    click_on "Record as already vaccinated"
  end

  def when_i_click_back
    click_on "Back"
  end

  def and_i_confirm_the_details
    click_on "Confirm"
  end

  def then_i_see_the_patient_session_page
    expect(page).to have_content("Session activity and notes")
  end

  def then_i_see_the_patient_is_already_vaccinated
    expect(page).to have_content("Vaccination outcome recorded for Td/IPV")
    expect(page).to have_content("LocationUnknown")
  end

  def and_the_patient_no_longer_appears_in_consent
    within(".nhsuk-breadcrumb__list") { click_on "Children" }
    within(".app-secondary-navigation") { click_on "Consent" }
    expect(page).not_to have_content(@patient.full_name)
  end

  def and_i_cannot_record_the_patient_as_already_vaccinated
    expect(page).not_to have_content("Record as already vaccinated")
  end

  def and_the_consent_requests_are_sent
    EnqueueSchoolConsentRequestsJob.perform_now
    perform_enqueued_jobs
  end

  def then_the_parent_doesnt_receive_a_consent_request
    expect(EmailDeliveryJob.deliveries).to be_empty
  end

  def and_i_click_on_triage
    click_on "Sessions", match: :first
    choose "Scheduled"
    click_on "Update results"
    click_on @session.location.name
    click_on "Triage"
  end

  def then_i_see_the_patient_doesnt_need_triage
    choose "Any"
    click_on "Update results"

    expect(page).not_to have_content(@patient.full_name)
  end
end
