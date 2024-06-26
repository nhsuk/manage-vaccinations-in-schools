# frozen_string_literal: true

require "rails_helper"

describe "User authentication" do
  scenario "Users log in, log out, and their redirect page is remembered" do
    given_that_i_have_an_account
    when_i_go_to_the_dashboard
    then_i_see_the_sign_in_form

    when_i_sign_in
    then_i_see_the_dashboard

    when_i_sign_out
    then_i_see_the_start_page

    when_i_go_to_the_sessions_page
    then_i_see_the_sign_in_form

    when_i_sign_in
    then_i_see_the_sessions_page
  end

  def given_that_i_have_an_account
    @user = create :user, password: "rosebud123"
  end

  def when_i_go_to_the_dashboard
    visit start_path
    click_link "Start now"
  end

  def then_i_see_the_sign_in_form
    expect(page).to have_content "Log in"
  end

  def when_i_sign_in
    fill_in "Email address", with: @user.email
    fill_in "Password", with: "rosebud123"
    click_button "Log in"
  end

  def then_i_see_the_dashboard
    expect(page).to have_content "Signed in successfully"
    expect(current_path).to eq dashboard_path
  end

  def when_i_sign_out
    click_button "Log out"
  end

  def then_i_see_the_start_page
    expect(page).to have_content "Signed out successfully"
    expect(current_path).to eq start_path
  end

  def when_i_go_to_the_sessions_page
    visit sessions_path
  end

  def then_i_see_the_sessions_page
    expect(page).to have_content "Signed in successfully"
    expect(current_path).to eq sessions_path
    expect(page).to have_content "Today’s sessions"
  end
end
