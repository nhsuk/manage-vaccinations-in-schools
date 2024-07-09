# frozen_string_literal: true

require "rails_helper"

RSpec.describe "User authentication with CIS2" do
  let(:test_team_ods_code) { "AB12" }

  let(:cis2_auth_mock) do
    {
      "provider" => :cis2,
      "uid" => "123456789012",
      "info" => {
        "name" => "Nurse Test",
        "email" => "nurse.test@example.nhs.uk",
        "email_verified" => nil,
        "nickname" => nil,
        "first_name" => "Nurse",
        "last_name" => "Test",
        "gender" => nil,
        "image" => nil,
        "phone" => nil,
        "urls" => {
          "website" => nil
        }
      },
      "extra" => {
        "raw_info" => {
          "nhsid_useruid" => "123456789012",
          "name" => "Flo Nurse",
          "nhsid_nrbac_roles" => [
            {
              "person_orgid" => "1111222233334444",
              "person_roleid" => "5555666677778888",
              "org_code" => test_team_ods_code,
              "role_name" =>
                "\"Admin and Clerical\":\"Admin and Clerical\":\"Privacy Officer\"",
              "role_code" => "S8002:G8003:R0001",
              "activities" => [
                "Receive Self Claimed LR Alerts",
                "Receive Legal Override and Emergency View Alerts",
                "Receive Sealing Alerts"
              ],
              "activity_codes" => %w[B0016 B0015 B0018]
            },
            {
              "person_orgid" => "1234123412341234",
              "person_roleid" => "5678567856785678",
              "org_code" => "CD34",
              "role_name" =>
                "\"Clinical\":\"Clinical Provision\":\"Nurse Access Role\"",
              "role_code" => "S8000:G8000:R8001",
              "activities" => [
                "Personal Medication Administration",
                "Perform Detailed Health Record",
                "Amend Patient Demographics",
                "Perform Patient Administration",
                "Verify Health Records"
              ],
              "activity_codes" => %w[B0428 B0380 B0825 B0560 B8028]
            }
          ],
          "given_name" => "Nurse",
          "family_name" => "Flo",
          "nhsid_user_orgs" => [
            {
              "org_name" => "LAVENDER TOWN HEALTH",
              "org_code" => test_team_ods_code
            },
            { "org_name" => "KANTO HEALTH ORG", "org_code" => "CD34" }
          ],
          "uid" => "555057896106",
          "email" => "nurse.flo@example.nhs.uk",
          "sub" => "123456789012",
          "subname" => "123456789012",
          "iss" => "http://localhost:4000/not/used",
          "selected_roleid" => "5555666677778888"
        }
      }
    }
  end

  scenario "going through the start page then signing out" do
    setup_cis2_auth_mock

    given_the_cis2_feature_flag_is_enabled
    and_the_test_team_is_setup_in_mavis
    when_i_go_to_the_start_page
    then_i_should_see_the_cis2_login_button

    when_i_click_the_cis2_login_button
    then_i_see_the_dashboard
    and_i_am_logged_in

    when_i_log_out
    then_i_am_on_the_start_page
    and_i_am_logged_out
  end

  scenario "going straight to the sessions page" do
    setup_cis2_auth_mock

    given_the_cis2_feature_flag_is_enabled
    and_the_test_team_is_setup_in_mavis
    when_i_go_to_the_sessions_page
    then_i_am_on_the_start_page

    when_i_click_the_cis2_login_button
    then_i_see_the_sessions_page
    and_i_am_logged_in
  end

  scenario "user has wrong team selected" do
    setup_cis2_auth_mock

    given_the_cis2_feature_flag_is_enabled
    when_i_go_to_the_sessions_page
    then_i_am_on_the_start_page

    when_i_click_the_cis2_login_button
    then_i_see_the_team_not_found_error

    given_my_team_is_setup_in_mavis
    when_i_click_the_change_role_button
    then_i_see_the_sessions_page
  end

  context "user has no other orgs to select" do
    let(:cis2_auth_mock) do
      super().tap do |mock|
        mock["extra"]["raw_info"]["nhsid_nrbac_roles"].select! do
          _1["org_code"] == test_team_ods_code
        end
      end
    end

    scenario "user has wrong team selected" do
      setup_cis2_auth_mock

      given_the_cis2_feature_flag_is_enabled
      when_i_go_to_the_start_page
      then_i_should_see_the_cis2_login_button

      when_i_click_the_cis2_login_button
      then_i_see_the_team_not_found_error
      and_there_is_no_change_role_button
    end
  end

  def setup_cis2_auth_mock
    OmniAuth.config.add_mock(:cis2, cis2_auth_mock)
  end

  def given_the_cis2_feature_flag_is_enabled
    Flipper.enable(:cis2)
  end

  def and_the_test_team_is_setup_in_mavis
    @team = create :team, ods_code: test_team_ods_code
  end
  alias_method :given_my_team_is_setup_in_mavis,
               :and_the_test_team_is_setup_in_mavis

  def when_i_go_to_the_start_page
    visit "/start"
  end

  def then_i_should_see_the_cis2_login_button
    expect(page).to have_button "Log in with my Care Identity"
  end

  def when_i_click_the_cis2_login_button
    click_button "Care Identity"
  end

  def then_i_see_the_dashboard
    expect(page).to have_current_path dashboard_path
  end

  def and_i_am_logged_in
    expect(page).to have_link "nurse.test@example.nhs.uk"
    expect(page).to have_button "Log out"
  end

  def when_i_log_out
    click_button "Log out"
  end

  def then_i_am_on_the_start_page
    expect(page).to have_current_path start_path
  end

  def and_i_am_logged_out
    expect(page).not_to have_link "nurse.test@example.nhs.uk"
    expect(page).not_to have_button "Log out"
  end

  def when_i_go_to_the_sessions_page
    visit sessions_path
  end

  def then_i_see_the_sessions_page
    expect(page).to have_current_path sessions_path
  end

  def then_i_see_the_team_not_found_error
    expect(
      page
    ).to have_heading "Your organisation is not using this service yet"
  end

  def when_i_click_the_change_role_button
    click_button "Change role"
  end

  def then_i_see_the_team_not_found_error
    expect(
      page
    ).to have_heading "Your organisation is not using this service yet"
  end

  def and_there_is_no_change_role_button
    expect(page).not_to have_button "Change role"
  end
end
