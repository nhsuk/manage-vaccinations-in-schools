# frozen_string_literal: true

describe "Parental consent" do
  scenario "Send request" do
    given_a_patient_without_consent_exists
    and_i_am_signed_in

    when_i_go_to_a_patient_without_consent
    then_i_see_no_requests_sent

    when_i_click_send_consent_request
    then_i_see_the_confirmation_banner
    and_i_see_a_consent_request_has_been_sent
    and_an_email_is_sent_to_the_parent
    and_a_text_is_sent_to_the_parent
  end

  def given_a_patient_without_consent_exists
    programme = create(:programme, :hpv)
    @team = create(:team, :with_one_nurse, programmes: [programme])

    location = create(:location, :generic_clinic, team: @team)

    @session = create(:session, team: @team, programme:, location:)
    @patient = create(:patient, session: @session)
    @parent = @patient.parents.first
  end

  def and_i_am_signed_in
    sign_in @team.users.first
  end

  def when_i_go_to_a_patient_without_consent
    visit session_consents_path(@session)
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
    expect_email_to(@parent.email, :hpv_session_consent_request_for_clinic)
  end

  def and_a_text_is_sent_to_the_parent
    expect_text_to(@parent.phone, :consent_request)
  end
end
