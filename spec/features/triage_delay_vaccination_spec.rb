# frozen_string_literal: true

describe "Triage" do
  scenario "delay vaccination" do
    given_a_programme_with_a_running_session
    and_i_am_signed_in
    when_i_go_to_the_triage_page

    when_i_click_on_a_patient
    and_i_enter_a_note_and_delay_vaccination
    then_i_see_an_alert_saying_the_record_was_saved
    and_a_vaccination_at_clinic_email_is_sent_to_the_parent

    when_i_filter_by_delay_vaccination
    then_i_see_the_patient

    when_i_access_the_vaccinate_later_page
    then_i_see_the_patient

    when_i_view_the_child_record
    then_they_should_have_the_status_banner_delay_vaccination
    and_i_am_not_able_to_record_a_vaccination
    and_i_am_able_to_update_the_triage
  end

  def given_a_programme_with_a_running_session
    programmes = [create(:programme, :hpv)]
    @organisation = create(:organisation, :with_one_nurse, programmes:)
    @school = create(:school, organisation: @organisation)
    session =
      create(
        :session,
        organisation: @organisation,
        programmes:,
        location: @school,
        date: Time.zone.today
      )
    @patient =
      create(
        :patient_session,
        :consent_given_triage_needed,
        :in_attendance,
        programmes:,
        session:
      ).patient
  end

  def and_i_am_signed_in
    sign_in @organisation.users.first
  end

  def when_i_go_to_the_triage_page
    visit "/dashboard"
    click_link "Sessions", match: :first
    click_link @school.name
    click_link "Triage"
  end

  def when_i_click_on_a_patient
    click_link @patient.full_name
  end

  def and_i_enter_a_note_and_delay_vaccination
    fill_in "Triage notes (optional)", with: "Delaying vaccination for 2 weeks"
    choose "No, delay vaccination (and invite to clinic)"
    click_button "Save triage"
  end

  def then_i_see_an_alert_saying_the_record_was_saved
    expect(page).to have_alert("Success", text: "Triage outcome updated")
  end

  def and_a_vaccination_at_clinic_email_is_sent_to_the_parent
    expect_email_to @patient.consents.first.parent.email,
                    :triage_vaccination_at_clinic
  end

  def when_i_filter_by_delay_vaccination
    click_on "Triage"
    choose "Delay vaccination"
    click_on "Update results"
  end

  def then_i_see_the_patient
    expect(page).to have_content(@patient.full_name)
  end

  def when_i_access_the_vaccinate_later_page
    click_on @school.name, match: :first
    click_on "Session outcomes"
    choose "No outcome yet"
    click_on "Update results"
  end

  def when_i_view_the_child_record
    click_link @patient.full_name
  end

  def then_they_should_have_the_status_banner_delay_vaccination
    expect(page).to have_content("Delay vaccination")
  end

  def and_i_am_not_able_to_record_a_vaccination
    expect(page).not_to have_content("ready for their HPV vaccination?")
  end

  def and_i_am_able_to_update_the_triage
    expect(page).to have_content("Update triage outcome")
  end
end
