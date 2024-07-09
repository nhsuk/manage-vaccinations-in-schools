# frozen_string_literal: true

require "rails_helper"
require "fixtures/cis2_auth_info"

describe "User CIS2 authentication" do
  let(:test_team_ods_code) { "AB12" }

  let(:cis2_auth_mock) do
    CIS2_AUTH_INFO.tap do |info|
      info["extra"]["raw_info"]["nhsid_nrbac_roles"][0][
        "org_code"
      ] = test_team_ods_code
      info["extra"]["raw_info"]["nhsid_user_orgs"][0][
        "org_code"
      ] = test_team_ods_code
    end
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

  def given_my_team_is_setup_in_mavis
    @team = create :team, ods_code: test_team_ods_code
  end

  def when_i_go_to_the_start_page
    visit "/start"
  end

  def when_i_click_the_cis2_login_button
    click_button "Care Identity"
  end

  def when_i_click_the_cis2_login_button
    click_button "Care Identity"
  end

  def then_i_am_on_the_start_page
    expect(page).to have_current_path start_path
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

  def and_there_is_no_change_role_button
    expect(page).not_to have_button "Change role"
  end

  def then_i_should_see_the_cis2_login_button
    expect(page).to have_button "Log in with my Care Identity"
  end
end
