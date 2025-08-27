# frozen_string_literal: true

describe "Patient Specific Directions" do
  before { given_delegation_feature_flag_is_enabled }

  scenario "Healthcare worked records nasal vaccination with PSD" do
    given_a_flu_programme_with_a_running_session(
      user_type: :with_one_healthcare_assistant
    )
    and_a_patient_with_a_psd_exists
    and_i_am_signed_in(role: :healthcare_assistant)

    when_i_visit_the_session_patient_programme_page
    and_i_record_that_the_patient_has_been_vaccinated_with_nasal_spray
    and_the_vaccination_record_has_psd_as_the_protocol
  end

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
    programmes = [@programme]

    @team = create(:team, user_type, programmes:)

    @batch =
      create(
        :batch,
        :not_expired,
        team: @team,
        vaccine: @programme.vaccines.nasal.first
      )

    @session =
      create(
        :session,
        :today,
        :requires_no_registration,
        :psd_enabled,
        team: @team,
        programmes:
      )
  end

  def and_a_patient_who_doesnt_need_triage_exists
    @patient =
      create(
        :patient,
        :consent_given_nasal_only_triage_not_needed,
        :in_attendance,
        session: @session
      )
  end

  def and_a_patient_with_a_psd_exists
    and_a_patient_who_doesnt_need_triage_exists

    create(
      :patient_specific_direction,
      patient: @patient,
      programme: @programme
    )
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

  def and_i_record_that_the_patient_has_been_vaccinated_with_nasal_spray
    within all("section")[0] do
      check "I have checked that the above statements are true"
    end

    within all("section")[1] do
      choose "Yes"
      click_button "Continue"
    end

    choose @batch.name
    click_button "Continue"
    click_on "Confirm"

    expect(page).to have_text("Vaccination outcome recorded for flu")
  end

  def and_the_vaccination_record_has_psd_as_the_protocol
    expect(@patient.vaccination_records.first.protocol).to eq("psd")
  end
end
