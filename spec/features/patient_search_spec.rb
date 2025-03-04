# frozen_string_literal: true

describe "Patient search" do
  scenario "Users can search for patients" do
    given_that_i_am_signed_in
    when_i_visit_the_patients_page
    then_i_see_all_patients

    when_i_search_for_cas
    then_i_see_patients_matching_cas
    and_i_see_the_search_count

    when_i_open_advanced_filters
    and_i_clear_the_search
    then_i_see_all_patients

    when_i_search_for_a
    then_i_see_patients_starting_with_a

    when_i_search_for_aa
    then_i_see_patients_starting_with_aa

    when_i_open_advanced_filters
    and_i_clear_the_search
    then_i_see_all_patients

    when_i_search_for_patients_without_nhs_numbers
    then_i_see_patients_without_nhs_numbers

    when_i_clear_the_search
    then_i_see_all_patients

    when_i_search_for_patients_by_date_of_birth
    then_i_see_patients_by_date_of_birth
  end

  def given_that_i_am_signed_in
    organisation = create(:organisation, :with_one_nurse)

    [
      %w[Aaron Smith],
      %w[Aardvark Jones],
      %w[Casey Brown],
      %w[Cassidy Wilson],
      %w[Bob Taylor]
    ].each do |(given_name, family_name)|
      create(:patient, given_name:, family_name:, organisation:)
    end

    create(
      :patient,
      given_name: "Salvor",
      family_name: "Hardin",
      organisation:,
      nhs_number: nil
    )

    create(
      :patient,
      given_name: "Hari",
      family_name: "Seldon",
      organisation:,
      date_of_birth: Date.new(2013, 1, 1)
    )

    sign_in organisation.users.first
  end

  def when_i_visit_the_patients_page
    visit patients_path
  end

  def then_i_see_all_patients
    expect(page).to have_content "Aaron Smith"
    expect(page).to have_content "Aardvark Jones"
    expect(page).to have_content "Casey Brown"
    expect(page).to have_content "Cassidy Wilson"
    expect(page).to have_content "Bob Taylor"
    expect(page).to have_content "Salvor Hardin"
    expect(page).to have_content "Hari Seldon"
  end

  def when_i_search_for_cas
    fill_in "Search", with: "cas"
    click_button "Search"
  end

  def then_i_see_patients_matching_cas
    expect(page).to have_content "Casey Brown"
    expect(page).to have_content "Cassidy Wilson"
    expect(page).not_to have_content "Aaron Smith"
    expect(page).not_to have_content "Aardvark Jones"
    expect(page).not_to have_content "Bob Taylor"
    expect(page).not_to have_content "Salvor Hardin"
    expect(page).not_to have_content "Hari Seldon"
  end

  def and_i_see_the_search_count
    expect(page).to have_content("2 children")
  end

  def when_i_open_advanced_filters
    find(".nhsuk-details__summary").click
  end

  def when_i_clear_the_search
    click_link "Clear filters"
  end

  alias_method :and_i_clear_the_search, :when_i_clear_the_search

  def when_i_search_for_a
    fill_in "Search", with: "a"
    click_button "Search"
  end

  def then_i_see_patients_starting_with_a
    expect(page).to have_content "Aaron Smith"
    expect(page).to have_content "Aardvark Jones"
    expect(page).not_to have_content "Bob Taylor"
    expect(page).not_to have_content "Casey Brown"
    expect(page).not_to have_content "Cassidy Wilson"
    expect(page).not_to have_content "Salvor Hardin"
    expect(page).not_to have_content "Hari Seldon"
  end

  def when_i_search_for_aa
    fill_in "Search", with: "a"
    click_button "Search"
  end

  def then_i_see_patients_starting_with_aa
    expect(page).to have_content "Aaron Smith"
    expect(page).to have_content "Aardvark Jones"
    expect(page).not_to have_content "Bob Taylor"
    expect(page).not_to have_content "Casey Brown"
    expect(page).not_to have_content "Cassidy Wilson"
    expect(page).not_to have_content "Salvor Hardin"
    expect(page).not_to have_content "Hari Seldon"
  end

  def when_i_search_for_patients_without_nhs_numbers
    find(".nhsuk-details__summary").click
    check "Missing NHS number"
    click_button "Update results"
  end

  def then_i_see_patients_without_nhs_numbers
    expect(page).not_to have_content "Aaron Smith"
    expect(page).not_to have_content "Aardvark Jones"
    expect(page).not_to have_content "Bob Taylor"
    expect(page).not_to have_content "Casey Brown"
    expect(page).not_to have_content "Cassidy Wilson"
    expect(page).to have_content "Salvor Hardin"
    expect(page).not_to have_content "Hari Seldon"
  end

  def when_i_search_for_patients_by_date_of_birth
    find(".nhsuk-details__summary").click
    fill_in "Day", with: "1"
    fill_in "Month", with: "1"
    fill_in "Year", with: "2013"
    click_button "Update results"
  end

  def then_i_see_patients_by_date_of_birth
    expect(page).not_to have_content "Aaron Smith"
    expect(page).not_to have_content "Aardvark Jones"
    expect(page).not_to have_content "Bob Taylor"
    expect(page).not_to have_content "Casey Brown"
    expect(page).not_to have_content "Cassidy Wilson"
    expect(page).not_to have_content "Salvor Hardin"
    expect(page).to have_content "Hari Seldon"
  end
end
