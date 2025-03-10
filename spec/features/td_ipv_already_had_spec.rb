# frozen_string_literal: true

describe "Td/IPV" do
  scenario "record a patient as already vaccinated outside the school session" do
    given_a_td_ipv_programme_with_a_session(clinic: false)
    and_a_patient_is_in_the_session

    when_i_go_the_session
    then_i_see_one_patient_needing_consent
    and_i_click_on_the_patient
    then_i_see_the_patient_needs_consent

    when_i_record_the_patient_as_already_vaccinated(clinic: false)
    and_the_consent_requests_are_sent
    then_the_parent_doesnt_receive_a_consent_request
  end

  scenario "record a patient as already vaccinated outside the clinic session" do
    given_a_td_ipv_programme_with_a_session(clinic: true)
    and_a_patient_is_in_the_session

    when_i_go_the_session
    then_i_see_one_patient_needing_consent
    and_i_click_on_the_patient
    then_i_see_the_patient_needs_consent

    when_i_record_the_patient_as_already_vaccinated(clinic: true)
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

    when_i_record_the_patient_as_already_vaccinated(clinic: false)
    and_i_click_on_triage
    then_i_see_the_patient_should_not_be_vaccinated
  end

  def given_a_td_ipv_programme_with_a_session(clinic:)
    @programme = create(:programme, :td_ipv)
    programmes = [@programme]

    organisation = create(:organisation, programmes:)
    @nurse = create(:nurse, organisations: [organisation])

    location =
      (
        if clinic
          organisation.generic_clinic
        else
          create(:school, :secondary, urn: 123_456, organisation:)
        end
      )

    create(:community_clinic, name: "Waterloo Hospital", organisation:)

    @session =
      create(
        :session,
        date: 1.week.from_now.to_date,
        organisation:,
        programmes:,
        location:
      )
  end

  def and_a_patient_is_in_the_session
    @patient = create(:patient, session: @session)
  end

  def and_the_patient_needs_triage
    create(:consent, :needing_triage, patient: @patient, programme: @programme)
  end

  def when_i_go_the_session
    sign_in @nurse
    visit dashboard_path
    click_on "Sessions", match: :first
    click_on "Scheduled"
    click_on @session.location.name
  end

  def then_i_see_one_patient_needing_consent
    click_on "Consent"

    choose "No response"
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

  def when_i_record_the_patient_as_already_vaccinated(clinic: false)
    click_on "Record as already vaccinated"

    if clinic
      choose "Waterloo Hospital"
      click_on "Continue"
    end

    click_on "Confirm"
  end

  def and_the_consent_requests_are_sent
    SchoolConsentRequestsJob.perform_now
  end

  def then_the_parent_doesnt_receive_a_consent_request
    expect(EmailDeliveryJob.deliveries).to be_empty
  end

  def and_i_click_on_triage
    click_on "Sessions"
    click_on "Scheduled"
    click_on @session.location.name
    click_on "Triage"
  end

  def then_i_see_the_patient_should_not_be_vaccinated
    choose "Do not vaccinate"
    click_on "Update results"

    expect(page).to have_content(@patient.full_name)
  end
end
