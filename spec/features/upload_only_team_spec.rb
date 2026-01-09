# frozen_string_literal: true

describe "Upload-only team homepage and navigation" do
  scenario "Homepage shows upload-only title and cards" do
    given_i_am_signed_in_as_an_upload_only_team
    when_i_visit_the_dashboard
    then_i_should_see_the_upload_only_cards
    and_i_should_see_the_import_records_card
    and_i_should_see_the_children_card
    and_i_should_see_the_reports_card
    and_i_should_see_the_national_reporting_service_name
  end

  scenario "Navigation shows only import, children and your team" do
    given_i_am_signed_in_as_an_upload_only_team
    when_i_visit_the_dashboard
    then_i_should_see_only_import_children_and_team_navigation_items
  end

  scenario "Children page search shows limited filters" do
    given_i_am_signed_in_as_an_upload_only_team
    when_i_visit_the_children_page
    then_i_should_see_limited_filters
  end

  scenario "Child record page shows vaccination records first and cannot be archived" do
    given_i_am_signed_in_as_an_upload_only_team
    and_i_upload_a_valid_file
    when_i_visit_the_children_page
    and_i_find_a_child
    then_i_should_see_vaccinations_then_child_details
    and_child_cannot_be_archived
    and_child_does_not_look_archived
  end

  def given_i_am_signed_in_as_an_upload_only_team
    @team =
      create(
        :team,
        :with_one_admin,
        :with_generic_clinic,
        programmes: [Programme.flu, Programme.hpv],
        ods_code: "XX99",
        type: :upload_only
      )
    create(:school, team: @team, urn: 100_000)
    sign_in @team.users.first
  end

  def when_i_visit_the_dashboard
    visit dashboard_path
  end

  def then_i_should_see_the_upload_only_cards
    cards = page.all(".nhsuk-card-group__item")
    expect(cards.count).to eq(4)
  end

  def and_i_should_see_the_import_records_card
    cards = page.all(".nhsuk-card-group__item")
    card = cards[0]

    expect(card).to have_css("h2", text: "Imports")
    expect(card).to have_link("Imports", href: imports_path)

    # Card should not be disabled
    expect(card).not_to have_css(".app-card--disabled")
  end

  def and_i_should_see_the_children_card
    cards = page.all(".nhsuk-card-group__item")
    card = cards[1]

    expect(card).to have_css("h2", text: "Children")
    expect(card).to have_link("Children", href: patients_path)
  end

  def and_i_should_see_the_reports_card
    cards = page.all(".nhsuk-card-group__item")
    card = cards[2]

    expect(card).to have_css("h2", text: "Reports")
    expect(card).not_to have_link("Reports")

    # Card should be disabled
    expect(card).to have_css(".app-card--disabled")
  end

  def then_i_should_see_only_import_children_and_team_navigation_items
    navigation_items = page.all(".nhsuk-header__navigation-item")
    expect(navigation_items.count).to eq(2)
    expect(navigation_items[0]).to have_link("Imports", href: imports_path)
    expect(navigation_items[1]).to have_link("Children", href: patients_path)
  end

  def when_i_visit_the_children_page
    visit patients_path
  end

  def then_i_should_see_limited_filters
    expect(page).to have_content(
      "Search for a child or use filters to see children matching your selection."
    )

    # Open the advanced filters details element
    find("summary", text: "Advanced filters").click

    form_groups = page.all(".nhsuk-form-group")
    expect(form_groups.count).to eq(7)
    expect(form_groups[0]).to have_content("Search")
    expect(form_groups[1]).to have_content("Year group")
    expect(form_groups[2]).to have_content("Date of birth")
    # form groups 3, 4 and 5 are form groups within the date of birth form group
    expect(form_groups[6]).to have_content("Children missing an NHS number")
  end

  def and_i_should_see_the_national_reporting_service_name
    page_title = page.first("h1")
    service_name = page.first(".nhsuk-header__service-name")
    expect(page_title.text).to eq(
      "Manage vaccinations in schools (Mavis) National reporting"
    )
    expect(service_name.text).to eq(
      "Manage vaccinations in schools – National reporting"
    )
  end

  def and_i_upload_a_valid_file
    visit imports_path
    click_on "Upload records"
    attach_file(
      "immunisation_import[csv]",
      "spec/fixtures/immunisation_import_bulk/valid_mixed_flu_hpv.csv"
    )
    click_on "Continue"
    wait_for_import_to_complete(ImmunisationImport)
    expect(page).to have_content("2 imported records")
  end

  def and_i_find_a_child
    fill_in "Search", with: "harry"
    click_on "Search"
    click_on "POTTER, Harry"
  end

  def then_i_should_see_vaccinations_then_child_details
    app_cards = page.all(".app-card")
    expect(app_cards.count).to eq(2)
    expect(app_cards[0]).to have_content("Vaccinations")
    expect(app_cards[1]).to have_content("Child’s details")
  end

  def and_child_cannot_be_archived
    app_card_buttons = page.all(".app-card .nhsuk-button")
    expect(app_card_buttons.count).to eq(1)
    expect(page).not_to have_content("Archive child record")
  end

  def and_child_does_not_look_archived
    expect(page).not_to have_content("Archived")
  end
end
