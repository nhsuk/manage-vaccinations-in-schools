# frozen_string_literal: true

describe "User account" do
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
    expect(find_field("Given name").value).to eq(@user.given_name)
    expect(find_field("Family name").value).to eq(@user.family_name)
    expect(find_field("Email").value).to eq(@user.email)
  end

  def when_i_edit_my_account_details
    fill_in "Given name", with: "New"
    fill_in "Family name", with: "Name"
    fill_in "Email", with: "newemail@example.com"
    click_button "Save changes"
  end

  def then_i_should_see_the_updated_account_details
    expect(find_field("Given name").value).to eq("New")
    expect(find_field("Family name").value).to eq("Name")
    expect(find_field("Email").value).to eq("newemail@example.com")
  end

  def when_i_submit_the_form_with_invalid_details
    fill_in "Given name", with: ""
    fill_in "Family name", with: ""
    fill_in "Email", with: "invalid-email"
    click_button "Save changes"
  end

  def then_i_should_see_the_error_messages
    expect(page).to have_content("Enter your given name")
    expect(page).to have_content("Enter your family name")
    expect(page).to have_content(
      "Enter a valid email address, such as j.doe@gmail.com"
    )
  end
end
