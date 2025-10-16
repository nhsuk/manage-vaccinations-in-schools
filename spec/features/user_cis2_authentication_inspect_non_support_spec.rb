# frozen_string_literal: true

describe "Inspect tools", :cis2 do
  scenario "Non-support user can't view timeline" do
    given_a_test_team_is_setup_in_mavis_and_cis2
    given_an_hpv_programme_is_underway

    when_i_login_as_a_nurse

    and_i_go_to_the_timeline_url_for_the_patient
    then_i_see_an_error
  end

  scenario "Non-support user can't view graph" do
    given_a_test_team_is_setup_in_mavis_and_cis2
    given_an_hpv_programme_is_underway

    when_i_login_as_a_nurse

    and_i_go_to_the_graph_url_for_the_patient
    then_i_see_an_error
  end

  def given_a_test_team_is_setup_in_mavis_and_cis2
    @user = create(:user, uid: "123")
    @team = create(:team, users: [@user])

    mock_cis2_auth(
      uid: "123",
      given_name: "Nurse",
      family_name: "User",
      org_code: @team.organisation.ods_code,
      org_name: @team.name,
      workgroups: [@team.workgroup]
    )
  end

  def given_an_hpv_programme_is_underway
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

  def when_i_login_as_a_nurse
    visit "/start"
    click_button "Care Identity"
    expect(page).to have_content("USER, Nurse")
    expect(page).to have_button("Log out")
  end

  def and_i_go_to_the_timeline_url_for_the_patient
    visit inspect_timeline_patient_path(id: @patient.id)
  end

  def and_i_go_to_the_graph_url_for_the_patient
    visit inspect_path(object_type: "patient", object_id: @patient.id)
  end

  def then_i_see_an_error
    expect(page).to have_content(
      "If you entered a web address, check it is correct."
    )
  end
end
