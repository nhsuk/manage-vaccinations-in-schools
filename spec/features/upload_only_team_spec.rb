# frozen_string_literal: true

describe "Upload-only team homepage and navigation" do
  scenario "Homepage shows upload-only cards" do
    given_i_am_signed_in_as_an_upload_only_team
    and_the_bulk_upload_feature_flag_is_enabled
    when_i_visit_the_dashboard
    then_i_should_see_the_upload_only_cards
    and_i_should_see_the_import_records_card
    and_i_should_see_the_vaccination_records_card
    and_i_should_see_the_reports_card
  end

  scenario "Navigation shows only import and your team" do
    given_i_am_signed_in_as_an_upload_only_team
    and_the_bulk_upload_feature_flag_is_enabled
    when_i_visit_the_dashboard
    then_i_should_see_only_import_and_team_navigation_items
  end

  def given_i_am_signed_in_as_an_upload_only_team
    @team = create(:team, :with_one_admin, ods_code: "XX99", type: :upload_only)
    sign_in @team.users.first
  end

  def and_the_bulk_upload_feature_flag_is_enabled
    Flipper.enable(:bulk_upload)
  end

  def when_i_visit_the_dashboard
    visit dashboard_path
  end

  def then_i_should_see_the_upload_only_cards
    cards = page.all(".nhsuk-card-group__item")
    expect(cards.count).to eq(5)
  end

  def and_i_should_see_the_import_records_card
    cards = page.all(".nhsuk-card-group__item")
    card = cards[0]

    expect(card).to have_css("h2", text: "Import records")
    expect(card).to have_link("Import records", href: imports_path)

    # Card should not be disabled
    expect(card).not_to have_css(".app-card--disabled")
  end

  def and_i_should_see_the_vaccination_records_card
    cards = page.all(".nhsuk-card-group__item")
    card = cards[1]

    expect(card).to have_css("h2", text: "Vaccination records")
    expect(card).not_to have_link("Vaccination records")

    # Card should be disabled
    expect(card).to have_css(".app-card--disabled")
  end

  def and_i_should_see_the_reports_card
    cards = page.all(".nhsuk-card-group__item")
    card = cards[2]

    expect(card).to have_css("h2", text: "Reports")
    expect(card).not_to have_link("Reports")

    # Card should be disabled
    expect(card).to have_css(".app-card--disabled")
  end

  def then_i_should_see_only_import_and_team_navigation_items
    navigation_items = page.all(".nhsuk-header__navigation-item")
    expect(navigation_items.count).to eq(2)
    expect(navigation_items[0]).to have_link("Imports", href: imports_path)
    expect(navigation_items[1]).to have_link("Your team", href: team_path)
  end
end
