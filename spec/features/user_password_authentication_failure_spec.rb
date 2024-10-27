# frozen_string_literal: true

# This test can be run by disabling CIS2 in consig/settings/test.yml and running
# rspec like so:
#
#   bundle exec rspec -t local_users
#
# There's likely a way to automate this but I haven't figured it out yet.
describe "User password authentication failure", :local_users do
  scenario "sign in with wrong password" do
    given_that_i_have_an_account_with_a_password

    when_i_go_to_the_start_page
    and_i_click_on_start_now
    and_i_click_on_log_in
    then_i_see_the_sign_in_form

    when_i_sign_in_with_the_wrong_password
    then_i_see_an_error_message
  end

  def given_that_i_have_an_account_with_a_password
    @user = create(:user, password: "rosebud123")
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
    expect(page).to have_content("Log in")
  end

  def when_i_sign_in_with_the_wrong_password
    fill_in "Email", with: @user.email
    fill_in "Password", with: "wrong password"
    click_button "Log in"
  end

  def then_i_see_an_error_message
    expect(page).to have_content("Invalid Email or password")
  end
end
