# frozen_string_literal: true

describe "MMR/MMRV" do
  around { |example| travel_to(Date.new(2025, 7, 1)) { example.run } }

  scenario "record a patient as already vaccinated outside the school session" do
    given_an_mmr_programme_with_a_session
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
    and_the_consent_requests_are_sent
    then_the_parent_doesnt_receive_a_consent_request
  end

  def given_an_mmr_programme_with_a_session(clinic: false)
    @programme = Programme.mmr
    programmes = [@programme]

    team = create(:team, programmes:)
    @nurse = create(:nurse, teams: [team])

    location =
      if clinic
        create(:generic_clinic, team:)
      else
        create(:school, urn: 123_456, team:)
      end

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
    @patient = create(:patient, :eligible_for_vaccination, :due_for_vaccination, session: @session)
  end

  def and_the_patient_doesnt_need_triage
    StatusUpdater.call(patient: @patient.reload)

    @patient.programme_statuses.each do |programme_status|
      programme_status.status = :needs_consent_no_response
      programme_status.save!
    end
    @patient.reload
  end

  def when_i_go_the_session
    sign_in @nurse
    visit dashboard_path
    click_on "Sessions", match: :first
    choose "Scheduled"
    click_on "Update results"
    click_on @session.location.name
  end

  def then_i_see_one_patient_needing_consent
    within(".app-secondary-navigation") { click_on "Children" }

    choose "Needs consent"
    click_on "Update results"

    expect(page).to have_content("Showing 1 to 1 of 1 children")
  end

  def and_i_click_on_the_patient
    click_on @patient.full_name
  end

  def then_i_see_the_patient_needs_consent
    expect(page).to have_content("No response")
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
    expect(page).to have_content("Vaccination outcome recorded for MMR")
    expect(page).to have_content("LocationUnknown")
  end

  def and_the_consent_requests_are_sent
    EnqueueSchoolConsentRequestsJob.perform_now
    perform_enqueued_jobs
  end

  def then_the_parent_doesnt_receive_a_consent_request
    expect(EmailDeliveryJob.deliveries).to be_empty
  end
end
