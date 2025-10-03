# frozen_string_literal: true

describe "Logout" do
  scenario "User navigates to the logout page" do
    given_i_am_signed_in
    when_i_navigate_to_the_logout_page
    then_i_see_the_logout_page

    when_i_click_on_the_logout_button
    then_i_am_logged_out
  end

  def given_i_am_signed_in
    @user = create(:user)
    sign_in @user
  end

  def when_i_navigate_to_the_logout_page
    visit logout_path
  end

  def then_i_see_the_logout_page
    expect(page).to have_content("You are about to log out")
    expect(page).to have_button("Log out")
  end

  def when_i_click_on_the_logout_button
    within "main" do
      click_button "Log out"
    end
  end

  def then_i_am_logged_out
    expect(page).to have_content("You have been logged out")
  end
end
