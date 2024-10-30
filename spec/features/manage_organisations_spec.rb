# frozen_string_literal: true

describe "Manage organisations" do
  scenario "Viewing organisation settings" do
    given_my_organisation_exists

    when_i_click_on_organisation_settings
    then_i_see_the_organisation_settings
  end

  def given_my_organisation_exists
    @organisation = create(:organisation, :with_one_nurse)
  end

  def when_i_click_on_organisation_settings
    sign_in @organisation.users.first

    visit "/dashboard"
    click_on "Your organisation", match: :first
  end

  def then_i_see_the_organisation_settings
    expect(page).to have_content("Contact details")
    expect(page).to have_content("Session defaults")
  end
end
