# frozen_string_literal: true

describe "Inspect timeline PII access logging", :cis2 do
  before { Flipper.enable(:ops_tools) }

  scenario "Support user with PII access visiting timeline" do
    prepare_support_organisation_with_pii_access
    prepare_hpv_programme_with_one_patient

    when_i_login_as_a_support_user_with_pii_access
    and_i_visit_a_patient_timeline_with_pii_enabled

    then_an_access_log_entry_is_created_for_the_patient
    and_the_access_log_entry_has_correct_attributes
  end

  scenario "Support user with PII access visiting timeline with comparison patient" do
    prepare_support_organisation_with_pii_access
    prepare_hpv_programme_with_two_patients

    when_i_login_as_a_support_user_with_pii_access
    and_i_visit_a_patient_timeline_with_pii_enabled_and_a_comparison_patient

    then_access_log_entries_are_created_for_both_patients
  end

  # Setup methods
  def prepare_support_organisation_with_pii_access
    mock_cis2_auth(
      uid: "123",
      given_name: "Support",
      family_name: "Test",
      org_code: "X26",
      workgroups: [CIS2Info::SUPPORT_WORKGROUP],
      role_code: CIS2Info::SUPPORT_ROLE,
      activity_codes: [
        CIS2Info::ACCESS_SENSITIVE_FLAGGED_RECORDS_ACTIVITY_CODE,
        CIS2Info::VIEW_DETAILED_HEALTH_RECORDS_ACTIVITY_CODE,
        CIS2Info::VIEW_SHARED_NON_PATIENT_IDENTIFIABLE_INFORMATION_ACTIVITY_CODE
      ]
    )
  end

  def prepare_hpv_programme_with_one_patient
    @team = create(:team, :with_one_nurse)
    @programme = create(:programme, :hpv, teams: [@team])
    @session =
      create(
        :session,
        date: Date.yesterday,
        team: @team,
        programmes: [@programme]
      )

    @patient =
      create(
        :patient,
        :consent_given_triage_needed,
        :triage_ready_to_vaccinate,
        given_name: "John",
        family_name: "Smith",
        year_group: 8,
        programmes: [@programme],
        team: @team,
        session: @session
      )
  end

  def prepare_hpv_programme_with_two_patients
    prepare_hpv_programme_with_one_patient

    @compare_patient =
      create(
        :patient,
        :consent_given_triage_needed,
        :triage_ready_to_vaccinate,
        given_name: "Jane",
        family_name: "Doe",
        year_group: 8,
        programmes: [@programme],
        team: @team,
        session: @session
      )
  end

  def when_i_login_as_a_support_user_with_pii_access
    visit "/start"
    click_button "Care Identity"
    expect(page).to have_content("TEST, Support")
    expect(page).to have_button("Log out")
  end

  def and_i_visit_a_patient_timeline_with_pii_enabled
    visit inspect_timeline_patient_path(id: @patient.id, show_pii: "true")
    expect(page).to have_content("Customise timeline")
  end

  def and_i_visit_a_patient_timeline_with_pii_enabled_and_a_comparison_patient
    visit inspect_timeline_patient_path(
            id: @patient.id,
            show_pii: "true",
            compare_option: "manual_entry",
            manual_patient_id: @compare_patient.id.to_s
          )
    expect(page).to have_content("Customise timeline")
  end

  def then_an_access_log_entry_is_created_for_the_patient
    # Two calls are made on first page load, so in this case (since we are visiting with show_pii: true),
    # two logs are created
    expect(@patient.access_log_entries.count).to eq(2)
  end

  def and_the_access_log_entry_has_correct_attributes
    verify_log_entry(@patient.access_log_entries.last)
  end

  def then_access_log_entries_are_created_for_both_patients
    # Check main patient log
    expect(@patient.access_log_entries.count).to eq(2)
    verify_log_entry(@patient.access_log_entries.last)

    # Check comparison patient log
    expect(@compare_patient.access_log_entries.count).to eq(1)
    verify_log_entry(@compare_patient.access_log_entries.includes(:user).last)
  end

  def verify_log_entry(log_entry)
    expect(User.find(log_entry.user_id).family_name).to eq("Test")
    expect(log_entry.controller).to eq("timeline")
    expect(log_entry.action).to eq("show_pii")
  end
end
