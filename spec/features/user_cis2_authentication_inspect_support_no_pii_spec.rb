# frozen_string_literal: true

describe "Inspect tools", :cis2 do
  scenario "Support user without PII access can view timeline but with PII checkbox disabled" do
    given_ops_tools_feature_flag_is_on
    given_a_test_support_organisation_is_setup_in_mavis_and_cis2
    given_an_hpv_programme_is_underway

    when_i_login_as_a_support_user_without_pii_access
    then_i_see_the_inspect_dashboard

    when_i_go_to_the_timeline_url_for_the_patient
    then_i_see_the_timeline_with_pii_checkbox_disabled
  end

  scenario "Support user without PII access can view graph but with PII checkbox disabled" do
    given_ops_tools_feature_flag_is_on
    given_a_test_support_organisation_is_setup_in_mavis_and_cis2
    given_an_hpv_programme_is_underway

    when_i_login_as_a_support_user_without_pii_access
    then_i_see_the_inspect_dashboard

    when_i_go_to_the_graph_url_for_the_patient
    then_i_see_the_graph_with_pii_checkbox_disabled
  end

  scenario "Support user without PII access can't view confidential pages" do
    given_ops_tools_feature_flag_is_on
    given_a_test_support_organisation_is_setup_in_mavis_and_cis2
    given_an_hpv_programme_is_underway

    when_i_login_as_a_support_user_without_pii_access

    and_i_go_to_a_confidential_page
    then_i_see_the_inspect_dashboard
  end

  scenario "`ops_tools` feature flag is off" do
    given_ops_tools_feature_flag_is_on
    given_a_test_support_organisation_is_setup_in_mavis_and_cis2
    given_an_hpv_programme_is_underway

    when_i_login_as_a_support_user_without_pii_access

    given_ops_tools_feature_flag_is_off
    when_i_go_to_the_timeline_url_for_the_patient

    then_a_page_not_found_error_is_displayed
  end

  def given_ops_tools_feature_flag_is_on
    Flipper.enable(:ops_tools)
  end

  def given_ops_tools_feature_flag_is_off
    Flipper.disable(:ops_tools)
  end

  def given_a_test_support_organisation_is_setup_in_mavis_and_cis2
    @ods_code = "X26"
    @team_support =
      create(:team, ods_code: @ods_code, workgroup: CIS2Info::SUPPORT_WORKGROUP)
    @user = create(:user, :support, team: @team_support)

    mock_cis2_auth(
      uid: "123",
      given_name: "Support",
      family_name: "Test",
      org_code: @ods_code,
      workgroups: [CIS2Info::SUPPORT_WORKGROUP],
      role_code: CIS2Info::SUPPORT_ROLE,
      activity_codes: [
        CIS2Info::VIEW_SHARED_NON_PATIENT_IDENTIFIABLE_INFORMATION_ACTIVITY_CODE
      ]
    )
  end

  def given_an_hpv_programme_is_underway
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
        :consent_given_triage_safe_to_vaccinate,
        given_name: "John",
        family_name: "Smith",
        year_group: 8,
        programmes: [@programme],
        team: @team,
        session: @session
      )
  end

  def when_i_login_as_a_support_user_without_pii_access
    visit "/start"
    click_button "Care Identity"
    expect(page).to have_content("TEST, Support")
    expect(page).to have_button("Log out")
  end

  def when_i_go_to_the_timeline_url_for_the_patient
    visit inspect_timeline_patient_path(id: @patient.id)
  end

  def when_i_go_to_the_graph_url_for_the_patient
    visit inspect_path(object_type: "patient", object_id: @patient.id)
  end

  def and_i_go_to_a_confidential_page
    visit patients_path
  end

  def then_i_see_the_timeline_with_pii_checkbox_disabled
    expect(page).to have_content("Customise timeline")

    expect(page).to have_field(
      "Show PII (not allowed for this user)",
      disabled: true
    )
  end

  def then_i_see_the_graph_with_pii_checkbox_disabled
    expect(page).to have_content("Graph options")

    find("summary", text: "Graph options").click
    expect(page).to have_field(
      "Show PII (not allowed for this user)",
      disabled: true
    )
  end

  def then_i_see_the_inspect_dashboard
    expect(page).to have_content("Operational support tools")
  end

  def then_a_page_not_found_error_is_displayed
    expect(page).to have_content("Page not found")
  end
end
