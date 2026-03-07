# frozen_string_literal: true

describe "Parental consent" do
  around { |example| travel_to(Date.new(2024, 1, 1)) { example.run } }

  scenario "Send school request where patient is eligible for HPV" do
    given_a_programme_exists(:hpv)
    and_a_school_session_with_hpv_eligible_patient_exists
    and_i_am_signed_in

    when_i_go_to_a_patient_without_consent
    then_i_see_no_requests_sent

    when_i_click_send_consent_request
    then_i_see_the_confirmation_banner
    and_i_see_a_consent_request_has_been_sent
    and_an_hpv_school_request_email_is_sent_to_the_parent
    and_an_hpv_school_request_sms_is_sent_to_the_parent

    when_i_click_on_session_activity_and_notes
    then_an_activity_log_entry_is_visible_for_the_email_tagged_as(
      "HPV",
      setting: :school
    )
  end

  scenario "Send clinic request where patient is eligible for HPV" do
    given_a_programme_exists(:hpv)
    and_a_patient_without_consent_exists
    and_i_am_signed_in

    when_i_go_to_a_patient_without_consent
    then_i_see_no_requests_sent

    when_i_click_send_consent_request
    then_i_see_the_confirmation_banner
    and_i_see_a_consent_request_has_been_sent
    and_a_clinic_request_email_is_sent_to_the_parent
    and_a_clinic_request_sms_is_sent_to_the_parent

    when_i_click_on_session_activity_and_notes
    then_an_activity_log_entry_is_visible_for_the_email("HPV")
    and_an_activity_log_entry_is_visible_for_the_text("HPV")
  end

  scenario "Send clinic request where patient is eligible for MMRV" do
    given_a_programme_exists(:mmr)
    and_a_patient_without_consent_exists
    and_i_am_signed_in

    when_i_go_to_a_patient_without_consent
    then_i_see_no_requests_sent

    when_i_click_send_consent_request
    then_i_see_the_confirmation_banner
    and_a_clinic_request_email_is_sent_to_the_parent
    and_a_clinic_request_sms_is_sent_to_the_parent

    when_i_click_on_session_activity_and_notes
    then_an_activity_log_entry_is_visible_for_the_email("MMRV")
    and_an_activity_log_entry_is_visible_for_the_text("MMRV")
  end

  scenario "Send school request where patient is eligible for MMRV" do
    given_a_programme_exists(:mmr)
    and_a_school_session_with_mmrv_eligible_patient_exists
    and_i_am_signed_in

    when_i_go_to_a_patient_without_consent
    then_i_see_no_requests_sent

    when_i_click_send_consent_request
    then_i_see_the_confirmation_banner
    and_an_mmrv_school_request_email_is_sent_to_the_parent
    and_an_mmrv_school_request_sms_is_sent_to_the_parent

    when_i_click_on_session_activity_and_notes
    then_an_activity_log_entry_is_visible_for_the_email_tagged_as(
      "MMRV",
      setting: :school
    )
  end

  scenario "Send school outbreak request where patient is eligible for MMRV" do
    given_a_programme_exists(:mmr)
    and_a_school_session_with_mmrv_eligible_patient_exists(outbreak: true)
    and_i_am_signed_in

    when_i_go_to_a_patient_without_consent
    then_i_see_no_requests_sent

    when_i_click_send_consent_request
    then_i_see_the_confirmation_banner
    and_an_mmrv_school_request_email_is_sent_to_the_parent(outbreak: true)
    and_an_mmrv_school_request_sms_is_sent_to_the_parent(outbreak: true)

    when_i_click_on_session_activity_and_notes
    then_an_activity_log_entry_is_visible_for_the_email_tagged_as(
      "MMRV",
      setting: :school,
      outbreak: true
    )
  end

  scenario "Send school request where patient is not eligible for MMRV" do
    given_a_programme_exists(:mmr)
    and_a_school_session_with_mmr_only_patient_exists
    and_i_am_signed_in

    when_i_go_to_a_patient_without_consent
    then_i_see_no_requests_sent

    when_i_click_send_consent_request
    then_i_see_the_confirmation_banner
    and_an_mmr_school_request_email_is_sent_to_the_parent
    and_an_mmr_school_request_sms_is_sent_to_the_parent

    when_i_click_on_session_activity_and_notes
    then_an_activity_log_entry_is_visible_for_the_email_tagged_as(
      "MMR",
      setting: :school
    )
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

    PatientStatusUpdater.call
  end

  def and_a_school_session_with_hpv_eligible_patient_exists(outbreak: false)
    create_school_session_with_patient(date_of_birth: 12.years.ago, outbreak:)
  end

  def and_a_school_session_with_mmrv_eligible_patient_exists(outbreak: false)
    create_school_session_with_patient(
      date_of_birth: Programme::MIN_MMRV_ELIGIBILITY_DATE + 1.month,
      outbreak:
    )
  end

  def and_a_school_session_with_mmr_only_patient_exists
    create_school_session_with_patient(
      date_of_birth: Programme::MIN_MMRV_ELIGIBILITY_DATE - 1.month
    )
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

  def and_a_clinic_request_email_is_sent_to_the_parent
    expect_email_to(@parent.email, :consent_clinic_request)
  end

  def and_a_clinic_request_sms_is_sent_to_the_parent
    expect_sms_to(@parent.phone, :consent_clinic_request)
  end

  def and_an_hpv_school_request_email_is_sent_to_the_parent
    expect_email_to(@parent.email, :consent_school_request_hpv)
  end

  def and_an_hpv_school_request_sms_is_sent_to_the_parent
    expect_sms_to(@parent.phone, :consent_school_request)
  end

  def and_an_mmrv_school_request_email_is_sent_to_the_parent(outbreak: false)
    template = "consent_school_request_mmrv"
    template += "_outbreak" if outbreak
    expect_email_to(@parent.email, template)
  end

  def and_an_mmrv_school_request_sms_is_sent_to_the_parent(outbreak: false)
    and_an_mmr_school_request_sms_is_sent_to_the_parent(
      mmrv_eligible: true,
      outbreak:
    )
  end

  def and_an_mmr_school_request_email_is_sent_to_the_parent
    expect_email_to(@parent.email, :consent_school_request_mmr)
  end

  def and_an_mmr_school_request_sms_is_sent_to_the_parent(
    mmrv_eligible: false,
    outbreak: false
  )
    dose_text = mmrv_eligible ? "MMR or MMRV vaccine?" : "MMR vaccine?"

    expect(sms_deliveries).to include(
      matching_notify_sms(
        phone_number: @parent.phone,
        template: :consent_school_request_mmr
      ).with_content_including("Has your child had 2 doses of the #{dose_text}")
    )

    outbreak_matcher =
      matching_notify_sms(
        phone_number: @parent.phone,
        template: :consent_school_request_mmr
      ).with_content_including(
        "Cases of measles in your area are high right now."
      )

    if outbreak
      expect(sms_deliveries).to include(outbreak_matcher)
    else
      expect(sms_deliveries).not_to include(outbreak_matcher)
    end
  end

  def when_i_click_on_session_activity_and_notes
    click_on "Session activity and notes"
  end

  def then_an_activity_log_entry_is_visible_for_the_email_tagged_as(
    programme_name,
    setting: :clinic,
    outbreak: false
  )
    outbreak_text = outbreak ? " outbreak" : ""
    location_text = setting.to_s
    programme_text = setting == :clinic ? "" : " #{programme_name.downcase}"
    title =
      "Consent #{location_text} request#{programme_text}#{outbreak_text} sent"

    expect(page).to have_content(
      "#{title}\n" \
        "#{programme_name} USER, Test · 1 January 2024 at 12:00am\n#{@parent.email}"
    )
  end

  def then_an_activity_log_entry_is_visible_for_the_email(programme_name)
    then_an_activity_log_entry_is_visible_for_the_email_tagged_as(
      programme_name
    )
  end

  def and_an_activity_log_entry_is_visible_for_the_text(programme_name)
    click_on "Session activity and notes"
    expect(page).to have_content(
      "Consent clinic request sent\n" \
        "#{programme_name} USER, Test · 1 January 2024 at 12:00am\n#{@parent.phone}"
    )
  end

  private

  def create_school_session_with_patient(date_of_birth:, outbreak: false)
    @team = create(:team, :with_one_nurse, programmes: @programmes)
    @user = @team.users.first

    location = create(:school, team: @team, programmes: @programmes)

    @session =
      create(
        :session,
        team: @team,
        programmes: @programmes,
        location:,
        date: Date.current + 2.days,
        outbreak:
      )

    @parent = create(:parent)
    @patient =
      create(:patient, session: @session, parents: [@parent], date_of_birth:)

    PatientStatusUpdater.call
  end
end
