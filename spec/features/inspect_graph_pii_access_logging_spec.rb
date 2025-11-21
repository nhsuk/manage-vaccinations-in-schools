# frozen_string_literal: true

describe "Inspect graph PII access logging", :cis2 do
  before { Flipper.enable(:ops_tools) }

  scenario "Support user with PII access visiting graph of patient" do
    prepare_support_organisation_with_pii_access
    prepare_hpv_programme_with_one_patient

    when_i_login_as_a_support_user_with_pii_access
    and_i_visit_a_patient_graph_with_pii_enabled

    then_an_access_log_entry_is_created_for_the_patient
    and_the_access_log_entry_has_correct_attributes
  end

  scenario "Support user with PII visiting graph of session related to patient" do
    prepare_support_organisation_with_pii_access
    prepare_hpv_programme_with_one_patient

    when_i_login_as_a_support_user_with_pii_access
    and_i_visit_a_parent_graph_with_pii_enabled

    then_an_access_log_entry_is_created_for_the_patient
    and_the_access_log_entry_has_correct_attributes
  end

  scenario "Support user with PII access visiting graph of patient with additional patients" do
    prepare_support_organisation_with_pii_access
    prepare_hpv_programme_with_two_patients

    when_i_login_as_a_support_user_with_pii_access
    and_i_visit_a_patient_graph_with_additional_patient

    then_access_logs_are_created_for_both_patients
    and_both_access_log_entries_have_correct_attributes
  end

  # Setup methods
  def prepare_support_organisation_with_pii_access
    @organisation_support = create(:organisation, ods_code: "X26")
    @team_support =
      create(
        :team,
        organisation: @organisation_support,
        workgroup: CIS2Info::SUPPORT_WORKGROUP
      )

    mock_cis2_auth(
      uid: "123",
      given_name: "Support",
      family_name: "Test",
      org_code: @organisation_support.ods_code,
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
    @programme = Programme.hpv
    @team = create(:team, :with_one_nurse, programmes: [@programme])
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

    @parent = create(:parent)
    create(:parent_relationship, parent: @parent, patient: @patient)
  end

  def prepare_hpv_programme_with_two_patients
    @programme = Programme.hpv
    @team = create(:team, :with_one_nurse, programmes: [@programme])
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

    @additional_patient =
      create(
        :patient,
        :consent_given_triage_safe_to_vaccinate,
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

  def and_i_visit_a_patient_graph_with_pii_enabled
    visit inspect_path(
            object_type: "patients",
            object_id: @patient.id,
            show_pii: ["true"],
            relationships: GraphRecords::DEFAULT_TRAVERSALS[:patient],
            additional_ids: {
              patient: ""
            }
          )
    expect(page).to have_content("Graph options")
  end

  def and_i_visit_a_parent_graph_with_pii_enabled
    visit inspect_path(
            object_type: "parents",
            object_id: @parent.id,
            show_pii: ["true"],
            relationships: GraphRecords::DEFAULT_TRAVERSALS[:parent],
            additional_ids: {
              parent: ""
            }
          )
    expect(page).to have_content("Graph options")
  end

  def and_i_visit_a_patient_graph_with_additional_patient
    visit inspect_path(
            object_type: "patient",
            object_id: @patient.id,
            show_pii: ["true"],
            relationships: GraphRecords::DEFAULT_TRAVERSALS[:patient],
            additional_ids: {
              patient: @additional_patient.id.to_s
            }
          )
    expect(page).to have_content("Graph options")
  end

  def then_an_access_log_entry_is_created_for_the_patient
    # One log is created when visiting with show_pii: true
    expect(@patient.access_log_entries.count).to eq(1)
  end

  def then_access_logs_are_created_for_both_patients
    # One log is created for each patient when visiting with show_pii: true
    expect(@patient.access_log_entries.count).to eq(1)
    expect(@additional_patient.access_log_entries.count).to eq(1)
  end

  def and_the_access_log_entry_has_correct_attributes
    verify_log_entry(@patient.access_log_entries.last)
  end

  def and_both_access_log_entries_have_correct_attributes
    verify_log_entry(@patient.access_log_entries.last)
    verify_log_entry(@additional_patient.access_log_entries.last)
  end

  def verify_log_entry(log_entry)
    expect(User.find(log_entry.user_id).family_name).to eq("Test")
    expect(log_entry.controller).to eq("graph")
    expect(log_entry.action).to eq("show_pii")
  end
end
