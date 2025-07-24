# frozen_string_literal: true

describe "Triage" do
  scenario "nurse can triage after importing historical vaccinations" do
    given_a_td_ipv_programme_with_a_session
    and_i_am_signed_in_as_a_nurse

    when_i_go_to_the_dashboard
    and_i_upload_historical_vaccination_records
    then_i_see_the_completed_upload

    when_i_go_the_session
    and_i_upload_the_class_list
    then_i_see_the_completed_upload

    when_i_go_the_session
    then_i_see_one_patient_needing_consent
    and_i_see_no_patients_needing_triage

    when_i_go_the_session
    and_the_parent_gives_consent
    and_i_click_on_triage
    then_i_see_one_patient_needing_triage
    and_i_click_on_the_patient
    then_i_see_the_patient_needs_triage
  end

  def given_a_td_ipv_programme_with_a_session
    @programme = create(:programme, :td_ipv)

    organisation =
      create(:organisation, :with_generic_clinic, programmes: [@programme])
    @user = create(:nurse, organisations: [organisation])

    location = create(:school, :secondary, urn: 123_456, organisation:)

    @session =
      create(
        :session,
        date: 1.week.from_now.to_date,
        organisation:,
        programmes: [@programme],
        location:
      )
  end

  def and_i_am_signed_in_as_a_nurse
    sign_in @user
  end

  def when_i_go_to_the_dashboard
    visit dashboard_path
  end

  def and_i_upload_historical_vaccination_records
    click_on "Import", match: :first
    click_on "Import records"
    choose "Vaccination records"
    click_on "Continue"

    attach_file(
      "immunisation_import[csv]",
      file_fixture("td_ipv/vaccination_records.csv")
    )
    click_on "Continue"
  end

  def then_i_see_the_completed_upload
    expect(page).to have_content("Completed")
  end

  def when_i_go_the_session
    click_on "Sessions", match: :first
    click_on "Scheduled"
    click_on @session.location.name
  end

  def and_i_upload_the_class_list
    click_on "Import class lists"

    check "Year 9"
    click_on "Continue"

    attach_file("class_import[csv]", file_fixture("td_ipv/class_list.csv"))
    click_on "Continue"
  end

  def then_i_see_one_patient_needing_consent
    click_on "Consent"

    check "No response"
    click_on "Update results"

    expect(page).to have_content("Showing 1 to 1 of 1 children")
  end

  def and_i_see_no_patients_needing_triage
    click_on "Triage"

    choose "Needs triage"
    click_on "Update results"

    expect(page).to have_content("No children matching search criteria found")
  end

  def and_the_parent_gives_consent
    create(:consent, :given, patient: Patient.first, programme: @programme)
    StatusUpdater.call(patient: @patient)

    page.refresh
  end

  def and_i_click_on_triage
    click_on "Triage"
  end

  def then_i_see_one_patient_needing_triage
    choose "Needs triage"
    click_on "Update results"

    expect(page).to have_content("Showing 1 to 1 of 1 children")
  end

  def and_i_click_on_the_patient
    click_on "PICKLE, Chyna"
  end

  def then_i_see_the_patient_needs_triage
    expect(page).to have_content("Needs triage")
    expect(page).to have_content(
      "Incomplete vaccination history for Td/IPV. Check if the child needs another dose."
    )
  end
end
