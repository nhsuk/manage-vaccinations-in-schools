# frozen_string_literal: true

describe "Invalidate consent" do
  scenario "Already given" do
    given_i_am_signed_in
    and_consent_has_been_given

    when_i_go_to_the_patient
    then_i_see_the_patient
    and_i_see_the_consent
    and_the_patient_is_ready_for_the_nurse

    when_i_click_on_the_consent
    then_i_see_the_consent
    and_i_click_invalidate_consent

    when_i_fill_in_the_notes
    and_i_click_invalidate_consent
    then_i_see_the_consent_has_been_invalidated
    and_i_cant_mark_as_invalid

    when_i_click_back
    then_i_see_the_patient
    and_i_see_the_consent
    and_i_am_not_able_to_record_a_vaccination
  end

  scenario "Already given and triaged" do
    given_i_am_signed_in
    and_consent_has_been_given
    and_triaged_as_safe_to_vaccinate

    when_i_go_to_the_patient
    then_i_see_the_patient
    and_i_see_the_consent
    and_the_patient_is_safe_to_vaccinate

    when_i_click_on_the_consent
    then_i_see_the_consent
    and_i_click_invalidate_consent

    when_i_fill_in_the_notes
    and_i_click_invalidate_consent
    then_i_see_the_consent_has_been_invalidated
    and_i_cant_mark_as_invalid

    when_i_click_back
    then_i_see_the_patient
    and_i_see_the_consent
    and_i_am_not_able_to_record_a_vaccination
  end

  def given_i_am_signed_in
    @programme = create(:programme, :hpv)
    organisation =
      create(:organisation, :with_one_nurse, programmes: [@programme])
    @session = create(:session, organisation:, programmes: [@programme])
    @patient = create(:patient, session: @session)

    sign_in organisation.users.first
  end

  def and_consent_has_been_given
    @consent =
      create(:consent, :given, patient: @patient, programme: @programme)
    create(
      :patient_consent_status,
      :given,
      patient: @patient,
      programme: @programme
    )
    @parent = @consent.parent
  end

  def and_triaged_as_safe_to_vaccinate
    create(:triage, patient: @patient, programme: @programme)
    create(
      :patient_triage_status,
      :safe_to_vaccinate,
      patient: @patient,
      programme: @programme
    )
  end

  def when_i_go_to_the_patient
    visit session_consent_path(@session)
    check "Consent given"
    click_on "Update results"
    click_link @patient.full_name
  end

  def then_i_see_the_patient
    expect(page).to have_content(@patient.full_name)
  end

  def then_i_see_the_consent
    expect(page).to have_content(@parent.full_name)
  end

  alias_method :and_i_see_the_consent, :then_i_see_the_consent

  def and_the_patient_is_ready_for_the_nurse
    expect(page).to have_content("ready for the vaccinator")
  end

  def and_the_patient_is_safe_to_vaccinate
    expect(page).to have_content("Safe to vaccinate")
  end

  def when_i_click_on_the_consent
    click_on @parent.full_name
  end

  def and_i_click_invalidate_consent
    click_on "Mark as invalid"
  end

  def when_i_fill_in_the_notes
    fill_in "Notes", with: "Some notes."
  end

  def then_i_see_the_consent_has_been_invalidated
    expect(page).to have_content("Invalid")
    expect(page).to have_content(
      "Consent response from #{@parent.full_name} marked as invalid"
    )
  end

  def and_i_cant_mark_as_invalid
    expect(page).not_to have_content("Mark as invalid")
  end

  def when_i_click_back
    click_on "Back"
  end

  def and_i_am_not_able_to_record_a_vaccination
    expect(page).to have_content("No response")
    expect(page).not_to have_content("ready for their HPV vaccination?")
  end
end
