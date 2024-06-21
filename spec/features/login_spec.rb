require "rails_helper"

RSpec.describe "Login" do
  scenario "with cis2 feature flag enabled" do
    given_the_cis2_feature_flag_is_enabled
    when_i_go_to_the_service
    then_i_should_see_the_cis2_login_button
  end

  scenario "with cis2 feature flag disabled" do
    given_the_cis2_feature_flag_is_disabled
    when_i_go_to_the_service
    then_i_should_see_the_start_now_button
    and_i_should_not_see_the_cis2_login_button
  end

  def given_the_cis2_feature_flag_is_enabled
    Flipper.enable(:cis2)
  end

  def given_the_cis2_feature_flag_is_disabled
    Flipper.disable(:cis2)
  end

  def when_i_go_to_the_service
    visit "/"
  end

  def then_i_should_see_the_cis2_login_button
    expect(page).to have_button "Care Identity"
  end

  def then_i_should_see_the_start_now_button
    expect(page).to have_link "Start now"
  end

  def and_i_should_not_see_the_cis2_login_button
    expect(page).not_to have_button "Care Identity"
  end
end
