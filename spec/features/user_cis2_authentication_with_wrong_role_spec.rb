# frozen_string_literal: true

require "rails_helper"
require "fixtures/cis2_auth_info"

describe "User CIS2 authentication" do
  let(:test_team_ods_code) { "AB12" }

  let(:cis2_auth_info) { CIS2_AUTH_INFO }

  scenario "user has wrong role selected" do
    given_the_cis2_feature_flag_is_enabled
    and_my_team_is_setup_in_mavis
    and_i_do_not_have_a_valid_role_for_mavis
    when_i_go_to_the_sessions_page
    then_i_am_on_the_start_page
    when_i_click_the_cis2_login_button
    then_i_see_the_team_not_found_error

    when_i_click_the_change_role_button_and_select_the_right_role
    then_i_see_the_sessions_page
  end

  def setup_cis2_auth_mock
    OmniAuth.config.add_mock(:cis2, cis2_auth_info)
  end

  def setup_role_in_cis2_response(code, name)
    cis2_auth_info.tap do |info|
      info["extra"]["raw_info"]["nhsid_nrbac_roles"][0]["role_code"] = code
      info["extra"]["raw_info"]["nhsid_nrbac_roles"][0]["role_name"] = name
    end

    setup_cis2_auth_mock
  end

  def given_the_cis2_feature_flag_is_enabled
    Flipper.enable(:cis2)
  end

  def and_my_team_is_setup_in_mavis
    @team = create :team, ods_code: test_team_ods_code
  end

  def and_i_do_not_have_a_valid_role_for_mavis
    setup_role_in_cis2_response(
      "S8002:G8003:R0001",
      '"Admin and Clerical":"Admin and Clerical":"Privacy Officer"'
    )
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
    ).to have_heading "You do not have permission to use this service"
  end

  def when_i_click_the_change_role_button_and_select_the_right_role
    # With don't actually get to select the right role directly in our test
    # setup so we change the cis2 response to simulate it.
    setup_role_in_cis2_response(
      "S8000:G8000:R8001",
      '"Clinical":"Clinical Provision":"Nurse Access Role"'
    )
    click_button "Change role"
  end
end
