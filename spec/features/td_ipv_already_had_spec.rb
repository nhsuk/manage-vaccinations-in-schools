# frozen_string_literal: true

describe "Td/IPV" do
  scenario "record a patient as already vaccinated outside the session" do
    given_a_menacwy_programme_with_a_session
    and_i_am_signed_in_as_a_nurse

    when_i_go_to_the_dashboard
    and_i_go_to_the_session
    and_i_upload_the_class_list
    then_i_see_the_completed_upload

    when_i_go_the_session
    then_i_see_one_patient_needing_consent

    when_i_click_on_consent
    and_i_click_on_the_patient
    then_i_see_the_patient_needs_consent

    when_i_record_the_patient_as_already_vaccinated
    and_the_consent_requests_are_sent
    then_the_parent_doesnt_receive_a_consent_request
  end

  def given_a_menacwy_programme_with_a_session
    programmes = [create(:programme, :menacwy)]

    organisation = create(:organisation, programmes:)
    @user = create(:nurse, organisations: [organisation])

    location = create(:school, :secondary, urn: 123_456, organisation:)

    @session =
      create(
        :session,
        date: 1.week.from_now.to_date,
        organisation:,
        programmes:,
        location:
      )
  end

  def and_i_am_signed_in_as_a_nurse
    sign_in @user
  end

  def when_i_go_to_the_dashboard
    visit dashboard_path
  end

  def when_i_go_the_session
    click_on "Sessions", match: :first
    click_on "Scheduled"
    click_on @session.location.name
  end

  alias_method :and_i_go_to_the_session, :when_i_go_the_session

  def and_i_upload_the_class_list
    click_on "Import class lists"

    check "Year 9"
    click_on "Continue"

    attach_file("class_import[csv]", file_fixture("menacwy/class_list.csv"))
    click_on "Continue"
  end

  def then_i_see_the_completed_upload
    expect(page).to have_content("Completed")
  end

  def then_i_see_one_patient_needing_consent
    click_on "Consent"

    choose "No response"
    click_on "Update results"

    expect(page).to have_content("Showing 1 to 1 of 1 children")

    click_on @session.location.name
  end

  def when_i_click_on_consent
    click_on "Consent"
  end

  def and_i_click_on_the_patient
    click_on "PICKLE, Chyna"
  end

  def then_i_see_the_patient_needs_consent
    expect(page).to have_content("No response")
  end

  def when_i_record_the_patient_as_already_vaccinated
    click_on "Record as already vaccinated"
    click_on "Confirm"
  end

  def and_the_consent_requests_are_sent
    SchoolConsentRequestsJob.perform_now
  end

  def then_the_parent_doesnt_receive_a_consent_request
    expect(EmailDeliveryJob.deliveries).to be_empty
  end
end
