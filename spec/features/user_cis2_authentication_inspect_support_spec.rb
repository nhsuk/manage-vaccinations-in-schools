# frozen_string_literal: true

describe "Inspect tools", :cis2 do
  scenario "Support user can view timeline" do
    given_a_test_support_organisation_is_setup_in_mavis_and_cis2
    given_an_hpv_programme_is_underway

    when_i_login_as_a_support_user

    and_i_go_to_the_timeline_url_for_the_patient
    then_i_see_the_timeline
  end

  scenario "Support user can view graph" do
    given_a_test_support_organisation_is_setup_in_mavis_and_cis2
    given_an_hpv_programme_is_underway

    when_i_login_as_a_support_user

    and_i_go_to_the_graph_url_for_the_patient
    then_i_see_the_graph
  end

  scenario "Support user can't view confidential pages" do
    given_a_test_support_organisation_is_setup_in_mavis_and_cis2
    given_an_hpv_programme_is_underway

    when_i_login_as_a_support_user

    and_i_go_to_a_confidential_page
    then_i_see_the_inspect_dashboard
  end

  def given_a_test_support_organisation_is_setup_in_mavis_and_cis2
    @organisation_support = create(:organisation, :with_one_support_user)

    mock_cis2_auth(
      uid: "123",
      given_name: "Support",
      family_name: "User",
      org_code: @organisation_support.ods_code,
      org_name: @organisation_support.name,
      workgroups: %w[mavissupport]
    )
  end

  def given_an_hpv_programme_is_underway
    @organisation = create(:organisation, :with_one_nurse)
    @programme = create(:programme, :hpv, organisations: [@organisation])
    @session =
      create(
        :session,
        date: Date.yesterday,
        organisation: @organisation,
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
        organisation: @organisation
      )

    create(:patient_session, patient: @patient, session: @session)
  end

  def when_i_login_as_a_support_user
    visit "/start"
    click_button "Care Identity"
    expect(page).to have_content("USER, Support")
    expect(page).to have_button("Log out")
  end

  def and_i_go_to_the_timeline_url_for_the_patient
    visit inspect_timeline_patient_path(id: @patient.id)
  end

  def and_i_go_to_the_graph_url_for_the_patient
    visit inspect_path(object_type: "patient", object_id: @patient.id)
  end

  def and_i_go_to_a_confidential_page
    visit patients_path
  end

  def then_i_see_the_timeline
    expect(page).to have_content("Customise timeline")
  end

  def then_i_see_the_graph
    expect(page).to have_content("Graph options")
  end

  def then_i_see_the_inspect_dashboard
    expect(page).to have_content("Operational support tools")
  end
end
