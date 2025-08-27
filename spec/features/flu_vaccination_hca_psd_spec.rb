# frozen_string_literal: true

describe "Patient Specific Directions" do
  before { given_delegation_feature_flag_is_enabled }

  scenario "prescriber can bulk add PSDs to patients that don't require triage" do
    given_a_flu_programme_with_a_running_session(user_type: :with_one_nurse)
    and_a_patient_who_doesnt_need_triage_exists
    and_i_am_signed_in

    when_i_go_to_the_session_psds_tab
    then_the_patient_should_have_psd_status_not_added
    and_i_should_see_one_child_eligible_for_psd

    when_i_click_add_new_psds
    and_should_see_again_one_child_eligible_for_psd

    when_i_click_on_button_to_bulk_add_psds
    then_the_patient_should_have_psd_status_added
    and_zero_children_should_be_eligible_for_psd
  end

  scenario "admin cannot bulk add PSDs to patients" do
    given_a_flu_programme_with_a_running_session(user_type: :with_one_admin)
    and_a_patient_who_doesnt_need_triage_exists
    and_i_am_signed_in(role: :admin)

    when_i_go_to_the_session_psds_tab
    then_i_should_not_see_link_to_bulk_add_psds
  end

  scenario "healthcare assistant cannot bulk add PSDs to patients" do
    given_a_flu_programme_with_a_running_session(
      user_type: :with_one_healthcare_assistant
    )
    and_a_patient_who_doesnt_need_triage_exists
    and_i_am_signed_in(role: :healthcare_assistant)

    when_i_go_to_the_session_psds_tab
    then_i_should_not_see_link_to_bulk_add_psds
  end

  scenario "viewing patients under record vaccinations that don't have PSD" do
    given_a_flu_programme_with_a_running_session(
      user_type: :with_one_healthcare_assistant
    )
    and_a_patient_without_a_psd_exists
    and_i_am_signed_in(role: :healthcare_assistant)

    when_i_visit_the_record_vaccinations_tab
    then_i_should_not_see_the_patient
  end

  scenario "when viewing a patient session with no PSD, there is no ability to record a vaccination" do
    given_a_flu_programme_with_a_running_session(
      user_type: :with_one_healthcare_assistant
    )
    and_a_patient_without_a_psd_exists
    and_i_am_signed_in(role: :healthcare_assistant)

    when_i_visit_the_session_patient_programme_page
    then_i_should_not_see_the_record_vaccination_section
  end

  def given_delegation_feature_flag_is_enabled
    Flipper.enable(:delegation)
  end

  def given_a_flu_programme_with_a_running_session(user_type:)
    @programme = create(:programme, :flu)
    @team = create(:team, user_type, programmes: [@programme])

    @batch = create(:batch, team: @team, vaccine: @programme.vaccines.first)

    @session = create(:session, team: @team, programmes: [@programme])
  end

  def and_a_patient_who_doesnt_need_triage_exists
    @patient =
      create(
        :patient_session,
        :consent_given_nasal_only_triage_not_needed,
        :in_attendance,
        session: @session
      ).patient
  end

  alias_method :and_a_patient_without_a_psd_exists,
               :and_a_patient_who_doesnt_need_triage_exists

  def and_i_am_signed_in(role: :nurse)
    @user = @team.users.first
    sign_in @user, role:
  end

  def when_i_go_to_the_session_psds_tab
    visit session_patient_specific_directions_path(@session)
  end

  def when_i_visit_the_record_vaccinations_tab
    visit session_record_path(@session)
  end

  def when_i_visit_the_session_patient_programme_page
    visit session_patient_programme_path(@session, @patient, @programme)
  end

  def then_the_patient_should_have_psd_status_not_added
    expect(page).to have_text("PSD not added")
  end

  def then_the_patient_should_have_psd_status_added
    expect(page).to have_text("PSD added")
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

  def then_i_should_not_see_the_patient
    expect(page).not_to have_text(@patient.given_name)
  end

  def then_i_should_not_see_the_record_vaccination_section
    expect(page).not_to have_text("Record flu vaccination with injection")
  end
end
