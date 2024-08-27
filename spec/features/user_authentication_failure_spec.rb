# frozen_string_literal: true

describe "User authentication failure" do
  scenario "user enters wrong username or password" do
    given_that_i_have_an_account
    when_i_go_to_the_start_page
    and_i_click_on_start_now
    and_i_click_on_log_in
    then_i_see_the_sign_in_form
  end

  def given_that_i_have_an_account
    @user = create :user, password: "rosebud123"
  end

  def when_i_go_to_the_start_page
    visit start_path
  end

  def and_i_click_on_start_now
    click_link "Start now"
  end

  def and_i_click_on_log_in
    click_button "Log in"
  end

  def then_i_see_the_sign_in_form
    expect(page).to have_selector :heading, "Log in"
  end
end
