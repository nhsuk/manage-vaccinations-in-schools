# frozen_string_literal: true

describe "Manage teams" do
  scenario "Viewing team settings" do
    given_my_team_exists

    when_i_click_on_team_settings
    then_i_see_the_team_contact_details

    when_i_click_on_clinics
    then_i_see_the_team_clinics

    when_i_click_on_schools
    then_i_see_the_team_schools

    when_i_click_on_sessions
    then_i_see_the_team_sessions
  end

  scenario "Adding a school site" do
    given_my_team_exists

    when_i_click_on_team_settings
    when_i_click_on_schools
    then_i_see_the_team_schools

    when_i_click_on_add_a_new_school_site
    then_i_see_the_select_school_site_form

    when_i_select_a_school
    and_i_continue
    then_i_see_the_school_site_details_form

    when_i_fill_in_the_school_site_details
    and_i_continue
    then_i_see_the_check_and_confirm_screen

    when_i_confirm
    then_i_see_the_school_site_confirmation_banner
    and_a_school_site_is_created

    when_i_go_back
    then_i_am_redirected_to_the_start_of_the_wizard
  end

  scenario "Editing a school site" do
    given_my_team_exists
    and_sites_exist

    when_i_click_on_team_settings
    when_i_click_on_schools
    then_i_see_the_team_schools
    and_i_can_only_edit_school_sites

    when_i_click_on_edit_a_school_site
    then_i_see_the_school_summary_with_edit_links

    when_i_click_on_change_name
    and_i_fill_in_the_new_name_with_same_value_as_another_site
    then_i_see_a_name_validation_error

    when_i_fill_in_the_new_name
    and_i_continue
    then_i_see_the_name_is_updated

    when_i_click_on_change_address
    and_i_fill_in_the_new_address
    and_i_continue
    then_i_see_the_address_is_updated

    when_i_click_continue
    then_i_see_the_team_schools
    and_the_site_details_are_updated
  end

  def given_my_team_exists
    @team = create(:team, :with_one_nurse)
    create(:school, team: @team, urn: "12345")
    create(:school, team: @team, urn: "34567")
    create(:community_clinic, team: @team)
  end

  def and_sites_exist
    @site_a = @team.schools.first
    @site_a.update!(site: "A")

    @site_b =
      create(:school, team: @team, urn: @site_a.urn, site: "B", name: "Site B")
  end

  def when_i_click_on_team_settings
    sign_in @team.users.first

    visit "/dashboard"
    click_on "Your team", match: :first
  end

  def then_i_see_the_team_contact_details
    expect(page).to have_content("Contact details")
  end

  def when_i_click_on_clinics
    click_on "Clinics"
  end

  def then_i_see_the_team_clinics
    expect(page).to have_content("Clinics")
    expect(page).to have_content(@team.community_clinics.first.name)
    expect(page).to have_content(@team.community_clinics.first.address_line_1)
  end

  def when_i_click_on_schools
    find(".app-sub-navigation__link", text: "Schools").click
  end

  def then_i_see_the_team_schools
    expect(page).to have_content("Schools")
    expect(page).to have_content(@team.schools.first.name)
    expect(page).to have_content(@team.schools.first.address_line_1)
  end

  def and_i_can_only_edit_school_sites
    expect(page).not_to have_link("Edit", href: edit_team_school_path("34567"))

    expect(page).to have_link("Edit", href: edit_team_school_path("12345A"))
    expect(page).to have_link("Edit", href: edit_team_school_path("12345B"))
  end

  def when_i_click_on_edit_a_school_site
    within("tr", text: "Site B") { click_on "Edit" }
  end

  def then_i_see_the_school_summary_with_edit_links
    expect(page).to have_content("Site B")
    expect(page).to have_link("Change", text: /name/i)
    expect(page).to have_link("Change", text: /address/i)
  end

  def when_i_click_on_change_name
    click_on "Change name"
  end

  def and_i_fill_in_the_new_name_with_same_value_as_another_site
    fill_in "School name", with: @site_a.name
    click_on "Continue"
  end

  def then_i_see_a_name_validation_error
    expect(page).to have_content("This site name is already in use")
  end

  def when_i_fill_in_the_new_name
    fill_in "School name", with: "Updated Site B Name"
  end

  def then_i_see_the_name_is_updated
    expect(page).to have_content("Updated Site B Name")
  end

  def when_i_click_on_change_address
    click_on "Change address"
  end

  def and_i_fill_in_the_new_address
    fill_in "Address line 1", with: "456 New Street"
    fill_in "Address line 2", with: "Floor 2"
    fill_in "Town", with: "New Town"
    fill_in "Postcode", with: "SW1A 2AA"
  end

  def then_i_see_the_address_is_updated
    expect(page).to have_content("456 New Street")
    expect(page).to have_content("New Town")
    expect(page).to have_content("SW1A 2AA")
  end

  def when_i_click_continue
    click_on "Continue"
  end

  def and_the_site_details_are_updated
    @site_b.reload
    expect(@site_b.name).to eq("Updated Site B Name")
    expect(@site_b.address_line_1).to eq("456 New Street")
    expect(@site_b.address_line_2).to eq("Floor 2")
    expect(@site_b.address_town).to eq("New Town")
    expect(@site_b.address_postcode).to eq("SW1A 2AA")
  end

  def when_i_click_on_sessions
    find(".app-sub-navigation__link", text: "Sessions").click
  end

  def then_i_see_the_team_sessions
    expect(page).to have_content("Session defaults")
  end

  def when_i_click_on_add_a_new_school_site
    click_on "Add a new school site"
  end

  def then_i_see_the_select_school_site_form
    expect(page).to have_content("Which school do you want to add a site to?")
  end

  alias_method :then_i_am_redirected_to_the_start_of_the_wizard,
               :then_i_see_the_select_school_site_form

  def when_i_select_a_school
    select @team.schools.first.name
  end

  def and_i_continue
    click_on "Continue"
  end

  alias_method :when_i_continue, :and_i_continue

  def then_i_see_the_school_site_details_form
    expect(page).to have_content("Site details")
  end

  def when_i_fill_in_the_school_site_details
    fill_in "Name", with: "New School Site"
    fill_in "Address line 1", with: "123 Main St"
    fill_in "Address line 2", with: "Suite 100"
    fill_in "Town", with: "Anytown"
    fill_in "Postcode", with: "SW1A 1AA"
  end

  def then_i_see_the_check_and_confirm_screen
    expect(page).to have_content("Check and confirm")
    expect(page).to have_content("12345B")
  end

  def when_i_confirm
    click_on "Add site"
  end

  def then_i_see_the_school_site_confirmation_banner
    expect(page).to have_content("New School Site has been added to your team.")
  end

  def and_a_school_site_is_created
    expect(Location.school.count).to eq(3)

    site = Location.school.last
    expect(site.name).to eq("New School Site")
    expect(site.address_line_1).to eq("123 Main St")
    expect(site.address_line_2).to eq("Suite 100")
    expect(site.address_town).to eq("Anytown")
    expect(site.address_postcode).to eq("SW1A 1AA")
    expect(site.urn).to eq("12345")
    expect(site.site).to eq("B")
    expect(site.teams).to include(@team)
  end

  def when_i_go_back
    visit draft_school_site_path("confirm")
  end
end
