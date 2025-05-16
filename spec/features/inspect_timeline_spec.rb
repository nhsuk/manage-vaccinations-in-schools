# frozen_string_literal: true

describe "Inspect timeline" do
  scenario "User can view timeline with support access" do
    given_an_hpv_programme_is_underway
    when_i_sign_in_as_a_support_user
    and_i_go_to_the_timeline_url_for_the_patient
    then_i_see_the_timeline
  end

  scenario "User can't view timeline without support access" do
    given_an_hpv_programme_is_underway
    when_i_sign_in
    and_i_go_to_the_timeline_url_for_the_patient
    then_i_see_an_error
  end

  scenario "User cannot view other pages with support access" do
    given_an_hpv_programme_is_underway
    when_i_sign_in_as_a_support_user
    and_i_go_to_a_confidential_page
    then_i_see_an_error
  end
end

def given_an_hpv_programme_is_underway
  @organisation = create(:organisation, :with_one_support_user)
  nurse = create(:nurse, organisation: @organisation)
  @organisation.users << nurse
  @programme = create(:programme, :hpv, organisations: [@organisation])

  @session =
    create(
      :session,
      date: Date.yesterday,
      organisation: @organisation,
      programmes: [@programme]
    )

  @patient =
    create(
      :patient,
      :consent_given_triage_needed,
      :triage_ready_to_vaccinate,
      given_name: "John",
      family_name: "Smith",
      year_group: 8,
      programmes: [@programme],
      organisation: @organisation
    )

  @patient_session =
    create(:patient_session, patient: @patient, session: @session)
end

def when_i_sign_in
  sign_in @organisation.users.second
end

def when_i_sign_in_as_a_support_user
  sign_in @organisation.users.first, support: true
end

def and_i_go_to_the_timeline_url_for_the_patient
  visit inspect_timeline_patient_path(
          id: @patient.id,
          event_names:
            Inspect::Timeline::PatientsController::DEFAULT_EVENT_NAMES,
          detail_config: TimelineRecords::DEFAULT_DETAILS_CONFIG,
          compare_option: nil
        )
end

def and_i_go_to_a_confidential_page
  visit patients_path
end

def then_i_see_the_timeline
  expect(page).to have_content("Inspect Patient-")
end

def then_i_see_an_error
  expect(page).to have_content("You are not authorised to access the page")
end
