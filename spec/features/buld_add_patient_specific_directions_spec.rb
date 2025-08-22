# frozen_string_literal: true

describe "Bulk add Patient Specific Directions (PSDs) to patients" do
  before { given_delegation_feature_flag_is_enabled }

  scenario "prescriber can bulk add PSDs to patients that don't require triage" do
    given_a_flu_programme_with_a_running_session
    and_a_patient_who_doesnt_need_triage_exists
    and_i_am_signed_in

    when_i_go_to_the_session_psds_tab
    then_the_patient_should_have_psd_status_not_added
    and_i_should_see_one_child_eligible_for_psd

    when_i_click_add_new_psds
    screenshot_and_save_page
    and_should_see_again_one_child_eligible_for_psd

    when_i_click_on_button_to_bulk_add_psds
    then_the_patient_should_have_psd_status_added
    and_zero_children_should_be_eligible_for_psd
  end

  def given_delegation_feature_flag_is_enabled
    Flipper.enable(:delegation)
  end

  def given_a_flu_programme_with_a_running_session
    programmes = [create(:programme, :flu)]
    @team = create(:team, :with_one_nurse, programmes:)

    @batch =
      create(:batch, team: @team, vaccine: programmes.first.vaccines.first)

    @session = create(:session, team: @team, programmes:)
  end

  def and_a_patient_who_doesnt_need_triage_exists
    @patient_triage_not_needed =
      create(
        :patient_session,
        :consent_given_triage_not_needed,
        session: @session
      ).patient
  end

  def and_i_am_signed_in
    @user = @team.users.first
    sign_in @user
  end

  def when_i_go_to_the_session_psds_tab
    visit session_patient_specific_directions_path(@session)
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
end
