# frozen_string_literal: true

describe "Patient Specific Directions" do
  before { given_delegation_feature_flag_is_enabled }

  scenario "prescriber can bulk add PSDs to patients that don't require triage" do
    given_a_flu_programme_with_a_running_session(user_type: :with_one_nurse)
    and_a_patient_with_consent_given_nasal_only_triage_not_needed
    and_a_patient_with_consent_given_injection_only_triage_not_needed
    and_i_am_signed_in(role: :prescriber)

    when_i_go_to_the_session_psds_tab
    then_the_patients_should_have_psd_status_not_added
    and_i_should_only_see_one_child_eligible_for_bulk_adding_psd
    and_i_should_see_one_child_eligible_for_psd

    when_i_click_add_new_psds
    and_should_see_again_one_child_eligible_for_psd

    when_i_click_on_button_to_bulk_add_psds
    then_the_nasal_patient_should_have_psd_status_added
    and_the_injection_patient_should_have_psd_status_not_added
    and_zero_children_should_be_eligible_for_psd
  end

  scenario "admin cannot bulk add PSDs to patients" do
    given_a_flu_programme_with_a_running_session(user_type: :with_one_admin)
    and_a_patient_with_consent_given_nasal_only_triage_not_needed
    and_i_am_signed_in(role: :admin)

    when_i_go_to_the_session_psds_tab
    then_i_should_not_see_link_to_bulk_add_psds
  end

  scenario "healthcare assistant cannot bulk add PSDs to patients" do
    given_a_flu_programme_with_a_running_session(
      user_type: :with_one_healthcare_assistant
    )
    and_a_patient_with_consent_given_nasal_only_triage_not_needed
    and_i_am_signed_in(role: :healthcare_assistant)

    when_i_go_to_the_session_psds_tab
    then_i_should_not_see_link_to_bulk_add_psds
  end

  def given_delegation_feature_flag_is_enabled
    Flipper.enable(:delegation)
  end

  def given_a_flu_programme_with_a_running_session(user_type:)
    @programmes = [create(:programme, :flu)]
    @team = create(:team, user_type, programmes: @programmes)

    @batch =
      create(:batch, team: @team, vaccine: @programmes.first.vaccines.first)

    @session = create(:session, team: @team, programmes: @programmes)
  end

  def and_a_patient_with_consent_given_nasal_only_triage_not_needed
    @nasal_patient =
      create(
        :patient,
        :consent_given_nasal_only_triage_not_needed,
        programmes: @programmes,
        session: @session
      )
  end

  def and_a_patient_with_consent_given_injection_only_triage_not_needed
    @injection_patient =
      create(
        :patient,
        :consent_given_injection_only_triage_not_needed,
        programmes: @programmes,
        session: @session
      )
  end

  def and_i_am_signed_in(role:)
    sign_in @team.users.first, role:
  end

  def when_i_go_to_the_session_psds_tab
    visit session_patient_specific_directions_path(@session)
  end

  def then_the_patients_should_have_psd_status_not_added
    expect(page).to have_text("PSD not added")
  end

  def then_the_nasal_patient_should_have_psd_status_added
    expect_patient_to_have_psd_status(@nasal_patient, "PSD added")
  end

  def and_the_injection_patient_should_have_psd_status_not_added
    expect_patient_to_have_psd_status(@injection_patient, "PSD not added")
  end

  def and_i_should_see_one_child_eligible_for_psd
    expect(page).to have_text("There are 1 children")
  end

  def and_should_see_again_one_child_eligible_for_psd
    expect(page).to have_text("1 new PSDs?")
  end

  def and_zero_children_should_be_eligible_for_psd
    expect(page).to have_text("There are 0 children")
  end

  def when_i_click_add_new_psds
    click_link "Add new PSDs"
  end

  def when_i_click_on_button_to_bulk_add_psds
    click_button "Yes, add PSDs"
  end

  def then_i_should_not_see_link_to_bulk_add_psds
    expect(page).not_to have_text("Add new PSDs")
  end

  def and_i_should_only_see_one_child_eligible_for_bulk_adding_psd
    expect(page).to have_text(
      "There are 1 children with consent for the nasal flu vaccine"
    )
  end

  def expect_patient_to_have_psd_status(patient, status)
    full_name = "#{patient.family_name.upcase}, #{patient.given_name}"
    patient_link = page.find("a", text: full_name)
    patient_card = patient_link.ancestor(".nhsuk-card")
    expect(patient_card).to have_css(".nhsuk-tag", text: status)
  end
end
