# frozen_string_literal: true

describe "Patient search" do
  around { |example| travel_to(Date.new(2025, 7, 31)) { example.run } }

  scenario "Users can search for patients" do
    given_that_i_am_signed_in
    when_i_visit_the_patients_page
    then_i_see_all_patients

    when_i_search_by_name
    then_i_see_patients_matching_the_name
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

  scenario "Search result returns no patients" do
    given_that_i_am_signed_in

    when_i_visit_the_session_consent_tab
    and_i_search_for_a_name_that_doesnt_exist
    then_i_see_no_results

    when_i_visit_the_session_triage_tab
    and_i_search_for_a_name_that_doesnt_exist
    then_i_see_no_results

    when_i_visit_the_session_register_tab
    and_i_search_for_a_name_that_doesnt_exist
    then_i_see_no_results

    when_i_visit_the_session_record_tab
    and_i_search_for_a_name_that_doesnt_exist
    then_i_see_no_results

    when_i_visit_the_session_patients_tab
    and_i_search_for_a_name_that_doesnt_exist
    then_i_see_no_results
  end

  def given_that_i_am_signed_in
    programmes = [create(:programme, :hpv)]
    team = create(:team, :with_one_nurse, programmes:)

    location = create(:school, name: "Waterloo Road", team:)
    @session = create(:session, location:, team:, programmes:)

    [
      %w[Aaron Smith],
      %w[Aardvark Jones],
      %w[Casey Brown],
      %w[Cassidy Wilson],
      %w[Bob Taylor]
    ].each do |(given_name, family_name)|
      create(:patient, given_name:, family_name:, session: @session)
    end

    create(
      :patient,
      given_name: "Salvor",
      family_name: "Hardin",
      session: @session,
      nhs_number: nil
    )

    create(
      :patient,
      given_name: "Hari",
      family_name: "Seldon",
      session: @session,
      date_of_birth: Date.new(2013, 1, 1)
    )

    sign_in team.users.first
  end

  def when_i_visit_the_patients_page
    visit patients_path
  end

  def then_i_see_all_patients
    expect(page).to have_content("SMITH, Aaron")
    expect(page).to have_content("JONES, Aardvark")
    expect(page).to have_content("BROWN, Casey")
    expect(page).to have_content("WILSON, Cassidy")
    expect(page).to have_content("TAYLOR, Bob")
    expect(page).to have_content("HARDIN, Salvor")
    expect(page).to have_content("SELDON, Hari")
  end

  def when_i_search_by_name
    fill_in "Search", with: "Casy Brown" # intentional typo
    click_button "Search"
  end

  def then_i_see_patients_matching_the_name
    expect(page).to have_content("BROWN, Casey")
    expect(page).not_to have_content("WILSON, Cassidy")
    expect(page).not_to have_content("SMITH, Aaron")
    expect(page).not_to have_content("JONES, Aardvark")
    expect(page).not_to have_content("TAYLOR, Bob")
    expect(page).not_to have_content("HARDIN, Salvor")
    expect(page).not_to have_content("SELDON, Hari")
  end

  def and_i_see_the_search_count
    expect(page).to have_content("1 child")
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
    expect(page).to have_content("SMITH, Aaron")
    expect(page).to have_content("JONES, Aardvark")
    expect(page).not_to have_content("TAYLOR, Bob")
    expect(page).not_to have_content("BROWN, Casey")
    expect(page).not_to have_content("WILSON, Cassidy")
    expect(page).not_to have_content("HARDIN, Salvor")
    expect(page).not_to have_content("SELDON, Hari")
  end

  def when_i_search_for_aa
    fill_in "Search", with: "a"
    click_button "Search"
  end

  def then_i_see_patients_starting_with_aa
    expect(page).to have_content("SMITH, Aaron")
    expect(page).to have_content("JONES, Aardvark")
    expect(page).not_to have_content("TAYLOR, Bob")
    expect(page).not_to have_content("BROWN, Casey")
    expect(page).not_to have_content("WILSON, Cassidy")
    expect(page).not_to have_content("HARDIN, Salvor")
    expect(page).not_to have_content("SELDON, Hari")
  end

  def when_i_search_for_patients_without_nhs_numbers
    find(".nhsuk-details__summary").click
    check "Children missing an NHS number"
    click_button "Update results"
  end

  def then_i_see_patients_without_nhs_numbers
    expect(page).not_to have_content("SMITH, Aaron")
    expect(page).not_to have_content("JONES, Aardvark")
    expect(page).not_to have_content("TAYLOR, Bob")
    expect(page).not_to have_content("BROWN, Casey")
    expect(page).not_to have_content("WILSON, Cassidy")
    expect(page).to have_content("HARDIN, Salvor")
    expect(page).not_to have_content("SELDON, Hari")
  end

  def when_i_search_for_patients_by_date_of_birth
    find(".nhsuk-details__summary").click
    fill_in "Day", with: "1"
    fill_in "Month", with: "1"
    fill_in "Year", with: "2013"
    click_button "Update results"
  end

  def then_i_see_patients_by_date_of_birth
    expect(page).not_to have_content("SMITH, Aaron")
    expect(page).not_to have_content("JONES, Aardvark")
    expect(page).not_to have_content("TAYLOR, Bob")
    expect(page).not_to have_content("BROWN, Casey")
    expect(page).not_to have_content("WILSON, Cassidy")
    expect(page).not_to have_content("HARDIN, Salvor")
    expect(page).to have_content("SELDON, Hari")
  end

  def when_i_visit_the_session_consent_tab
    visit session_consent_path(@session)
  end

  def when_i_visit_the_session_triage_tab
    visit session_triage_path(@session)
  end

  def when_i_visit_the_session_register_tab
    visit session_register_path(@session)
  end

  def when_i_visit_the_session_record_tab
    visit session_record_path(@session)
  end

  def when_i_visit_the_session_patients_tab
    visit session_patients_path(@session)
  end

  def and_i_search_for_a_name_that_doesnt_exist
    fill_in "Search", with: "Name doesn't exist"
    click_on "Search"
  end

  def then_i_see_no_results
    expect(page).to have_content("No children matching search criteria found")
  end
end
