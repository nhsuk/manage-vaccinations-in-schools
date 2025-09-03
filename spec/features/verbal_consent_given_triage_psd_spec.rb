# frozen_string_literal: true

describe "Verbal consent" do
  scenario "Given flu nasal spray with PSD" do
    given_a_flu_programme_is_underway
    and_i_am_signed_in

    when_i_record_that_verbal_nasal_consent_was_given(add_psd: true)
    then_i_see_the_check_and_confirm_page
    and_i_see_the_flu_nasal_consent_given

    when_i_confirm_the_consent_response
    and_the_patients_status_is_safe_to_vaccinate_with_nasal_spray
    and_the_patient_has_a_patient_specific_direction
  end

  scenario "Given flu nasal spray without PSD" do
    given_a_flu_programme_is_underway
    and_i_am_signed_in

    when_i_record_that_verbal_nasal_consent_was_given(add_psd: false)
    then_i_see_the_check_and_confirm_page
    and_i_see_the_flu_nasal_consent_given

    when_i_confirm_the_consent_response
    and_the_patients_status_is_safe_to_vaccinate_with_nasal_spray
    and_the_patient_doesnt_have_a_patient_specific_direction
  end

  def given_a_flu_programme_is_underway
    create_programme(:flu)
  end

  def and_i_am_signed_in
    sign_in @team.users.first, role: :prescriber
  end

  def create_programme(programme_type)
    @programme = create(:programme, programme_type)
    programmes = [@programme]
    @team = create(:team, :with_one_nurse, programmes:)
    @session = create(:session, :psd_enabled, team: @team, programmes:)

    @parent = create(:parent)
    @patient = create(:patient, session: @session, parents: [@parent])

    StatusUpdater.call
  end

  def when_i_record_that_verbal_nasal_consent_was_given(add_psd:)
    visit session_consent_path(@session)

    click_link @patient.full_name
    click_button "Record a new consent response"

    # Who are you trying to get consent from?
    click_button "Continue"
    expect(page).to have_content(
      "Choose who you are trying to get consent from"
    )

    choose "#{@parent.full_name} (#{@patient.parent_relationships.first.label})"
    click_button "Continue"

    # Details for parent or guardian
    expect(page).to have_content(
      "Details for #{@parent.full_name} (#{@patient.parent_relationships.first.label})"
    )
    # don't change any details
    click_button "Continue"

    # How was the response given?
    choose "By phone"
    click_button "Continue"

    # Do they agree?
    choose "Yes, for the nasal spray"
    choose "No"
    click_button "Continue"

    9.times { |index| find_all(".nhsuk-fieldset")[index].choose "No" }

    click_button "Continue"

    choose "Yes, it’s safe to vaccinate with nasal spray"
    choose add_psd ? "Yes" : "No"
    click_button "Continue"
  end

  def then_i_see_the_check_and_confirm_page
    expect(page).to have_content("Check and confirm answers")
    expect(page).to have_content(["Method", "By phone"].join)
    expect(page).not_to have_content(
      "Confirmation of vaccination sent to parent"
    )
  end

  def and_i_see_the_flu_nasal_consent_given
    expect(page).to have_content("Consent givenNasal spray")
    expect(page).to have_content("Consent also given for injected vaccine?No")
  end

  def when_i_confirm_the_consent_response
    click_button "Confirm"
    expect(page).to have_content("Consent recorded for #{@patient.full_name}")
  end

  def and_the_patients_status_is_safe_to_vaccinate_with_nasal_spray
    click_link @patient.full_name, match: :first
    expect(page).to have_content("Safe to vaccinate with nasal spray")
  end

  def and_the_patient_has_a_patient_specific_direction
    expect(page).to have_content("PSD added")
  end

  def and_the_patient_doesnt_have_a_patient_specific_direction
    expect(page).to have_content("PSD not added")
  end
end
