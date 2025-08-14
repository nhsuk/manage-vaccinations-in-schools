# frozen_string_literal: true

describe "User password authentication", :local_users do
  before { given_the_cis2_feature_flag_is_disabled }

  scenario "going through the start page then signing out" do
    given_that_i_have_an_account
    when_i_go_to_the_start_page
    then_i_am_on_the_start_page

    when_i_click_start_now
    then_i_see_the_sign_in_form

    when_i_sign_in
    then_i_see_the_dashboard

    when_i_sign_out
    then_i_am_on_the_start_page
    and_i_am_logged_out
  end

  scenario "going straight to the sessions page" do
    given_that_i_have_an_account
    when_i_go_to_the_sessions_page
    then_i_am_on_the_start_page

    when_i_click_start_now
    then_i_see_the_sign_in_form

    when_i_sign_in
    then_i_see_the_sessions_page
  end

  def given_the_cis2_feature_flag_is_disabled
    Flipper.disable(:cis2)
  end

  def given_that_i_have_an_account
    @user = create :user, password: "rosebud123"
  end

  def when_i_go_to_the_start_page
    visit start_path
  end

  def then_i_am_on_the_start_page
    expect(page).to have_content "Manage vaccinations in schools (Mavis)"
    expect(page).to have_link "Start now"
  end

  def and_i_am_logged_out
    expect(page).not_to have_link @user.email
    expect(page).not_to have_button "Log out"
  end

  def when_i_click_start_now
    click_link "Start now"
  end

  def then_i_see_the_dashboard
    expect(page).to have_current_path dashboard_path, ignore_query: true
  end

  def when_i_sign_out
    click_button "Log out"
  end

  def when_i_go_to_the_dashboard
    visit dashboard_path
  end

  def then_i_see_the_sign_in_form
    expect(page).to have_content "Log in"
  end

  def when_i_sign_in
    fill_in "Email address", with: @user.email
    fill_in "Password", with: "rosebud123"
    click_button "Log in"
  end

  def when_i_go_to_the_sessions_page
    visit sessions_path
  end

  def then_i_see_the_sessions_page
    expect(page).to have_current_path sessions_path, ignore_query: true
    expect(page).to have_content "Sessions"
  end
end
