require "rails_helper"

RSpec.describe "User account", type: :feature do
  scenario "Users can edit their account details" do
    given_that_i_am_signed_in
    when_i_visit_my_account_page
    then_i_should_see_my_account_details

    when_i_edit_my_account_details
    then_i_should_see_the_updated_account_details

    when_i_submit_the_form_with_invalid_details
    then_i_should_see_the_error_messages
  end

  def given_that_i_am_signed_in
    @user = create(:user)
    sign_in @user
  end

  def when_i_visit_my_account_page
    visit users_account_path(@user)
  end

  def then_i_should_see_my_account_details
    expect(find_field("Full name").value).to eq(@user.full_name)
    expect(find_field("Email").value).to eq(@user.email)
    expect(find_field("Registration number").value).to eq(@user.registration)
  end

  def when_i_edit_my_account_details
    fill_in "Full name", with: "New Name"
    fill_in "Email", with: "newemail@example.com"
    fill_in "Registration number", with: "123456"
    click_button "Save changes"
  end

  def then_i_should_see_the_updated_account_details
    expect(find_field("Full name").value).to eq("New Name")
    expect(find_field("Email").value).to eq("newemail@example.com")
    expect(find_field("Registration number").value).to eq("123456")
  end

  def when_i_submit_the_form_with_invalid_details
    fill_in "Full name", with: ""
    fill_in "Email", with: "invalid-email"
    fill_in "Registration number", with: "a" * 256
    click_button "Save changes"
  end

  def then_i_should_see_the_error_messages
    expect(page).to have_content(
      "Enter a valid email address, such as j.doe@gmail.com"
    )
    expect(page).to have_content("Enter your full name")
    expect(page).to have_content(
      "Enter a registration number with fewer than 255 characters"
    )
  end
end
