# frozen_string_literal: true

describe "Parental consent" do
  around { |example| travel_to(Date.new(2024, 1, 1)) { example.run } }

  scenario "Send request" do
    given_a_programme_exists(:hpv)
    and_a_patient_without_consent_exists
    and_i_am_signed_in

    when_i_go_to_a_patient_without_consent
    then_i_see_no_requests_sent

    when_i_click_send_consent_request
    then_i_see_the_confirmation_banner
    and_i_see_a_consent_request_has_been_sent
    and_an_email_is_sent_to_the_parent
    and_a_text_is_sent_to_the_parent

    when_i_click_on_session_activity_and_notes
    then_an_activity_log_entry_is_visible_for_the_email_tagged_as("HPV")
    and_an_activity_log_entry_is_visible_for_the_text_tagged_as("HPV")
  end

  scenario "Send request where patient is eligible for MMRV" do
    given_a_programme_exists(:mmr)
    and_a_patient_without_consent_exists
    and_i_am_signed_in

    when_i_go_to_a_patient_without_consent
    then_i_see_no_requests_sent

    when_i_click_send_consent_request
    then_i_see_the_confirmation_banner
    and_an_email_is_sent_to_the_parent
    and_a_text_is_sent_to_the_parent

    when_i_click_on_session_activity_and_notes
    then_an_activity_log_entry_is_visible_for_the_email_tagged_as("MMRV")
    and_an_activity_log_entry_is_visible_for_the_text_tagged_as("MMRV")
  end

  def given_a_programme_exists(programme_type)
    @programmes = [Programme.public_send(programme_type)]
  end

  def and_a_patient_without_consent_exists
    @team = create(:team, :with_one_nurse, programmes: @programmes)
    @user = @team.users.first

    location = create(:generic_clinic, team: @team)

    @session =
      create(
        :session,
        team: @team,
        programmes: @programmes,
        location:,
        date: Date.current + 2.days
      )

    @parent = create(:parent)
    @patient =
      create(
        :patient,
        session: @session,
        parents: [@parent],
        date_of_birth: Programme::MIN_MMRV_ELIGIBILITY_DATE + 1.month
      )

    StatusUpdater.call
  end

  def and_i_am_signed_in
    sign_in @user
  end

  def when_i_go_to_a_patient_without_consent
    visit session_patients_path(@session)
    click_link @patient.full_name
  end

  def then_i_see_no_requests_sent
    expect(page).to have_content("No requests have been sent.")
  end

  def when_i_click_send_consent_request
    click_on "Send consent request"
  end

  def then_i_see_the_confirmation_banner
    expect(page).to have_content("Consent request sent.")
  end

  def and_i_see_a_consent_request_has_been_sent
    expect(page).to have_content(
      "No-one responded to our requests for consent."
    )
    expect(page).to have_content("A request was sent on")
  end

  def and_an_email_is_sent_to_the_parent
    expect_email_to(@parent.email, :consent_clinic_request)
  end

  def and_a_text_is_sent_to_the_parent
    expect_sms_to(@parent.phone, :consent_clinic_request)
  end

  def when_i_click_on_session_activity_and_notes
    click_on "Session activity and notes"
  end

  def then_an_activity_log_entry_is_visible_for_the_email_tagged_as(
    programme_name
  )
    expect(page).to have_content(
      "Consent clinic request sent\n#{@parent.email}\n" \
        "#{programme_name}   1 January 2024 at 12:00am · USER, Test"
    )
  end

  def and_an_activity_log_entry_is_visible_for_the_text_tagged_as(
    programme_name
  )
    click_on "Session activity and notes"
    expect(page).to have_content(
      "Consent clinic request sent\n#{@parent.phone}\n" \
        "#{programme_name}   1 January 2024 at 12:00am · USER, Test"
    )
  end
end
