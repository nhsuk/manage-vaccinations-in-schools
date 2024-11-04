# frozen_string_literal: true

describe "Patient search" do
  scenario "Users can search for patients" do
    given_that_i_am_signed_in
    when_i_visit_the_patients_page
    then_i_see_all_patients

    when_i_search_for_cas
    then_i_see_patients_matching_cas
    and_i_see_the_search_count

    when_i_clear_the_search
    then_i_see_all_patients

    when_i_search_for_a
    then_i_see_patients_starting_with_a

    when_i_search_for_aa
    then_i_see_patients_starting_with_aa
  end

  def given_that_i_am_signed_in
    @organisation = create(:organisation, :with_one_nurse)
    @user = @organisation.users.first
    @cohort = create(:cohort, organisation: @organisation)

    # Create test patients with various names
    [
      %w[Aaron Smith],
      %w[Aardvark Jones],
      %w[Casey Brown],
      %w[Cassidy Wilson],
      %w[Bob Taylor]
    ].each do |(given_name, family_name)|
      create(:patient, given_name:, family_name:, cohort: @cohort)
    end

    sign_in @user
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
  end

  def when_i_search_for_cas
    find(".nhsuk-details__summary").click
    fill_in "Name", with: "cas"
    click_button "Update children"
  end

  def then_i_see_patients_matching_cas
    expect(page).to have_content "Casey Brown"
    expect(page).to have_content "Cassidy Wilson"
    expect(page).not_to have_content "Aaron Smith"
    expect(page).not_to have_content "Aardvark Jones"
    expect(page).not_to have_content "Bob Taylor"
  end

  def and_i_see_the_search_count
    expect(page).to have_content "2 children matching \"cas\""
  end

  def when_i_clear_the_search
    click_link "Clear filters"
  end

  def when_i_search_for_a
    find(".nhsuk-details__summary").click
    fill_in "Name", with: "a"
    click_button "Update children"
  end

  def then_i_see_patients_starting_with_a
    expect(page).to have_content "Aaron Smith"
    expect(page).to have_content "Aardvark Jones"
    expect(page).not_to have_content "Bob Taylor"
    expect(page).not_to have_content "Casey Brown"
    expect(page).not_to have_content "Cassidy Wilson"
  end

  def when_i_search_for_aa
    fill_in "Name", with: "aa"
    click_button "Update children"
  end

  def then_i_see_patients_starting_with_aa
    expect(page).to have_content "Aaron Smith"
    expect(page).to have_content "Aardvark Jones"
    expect(page).not_to have_content "Bob Taylor"
    expect(page).not_to have_content "Casey Brown"
    expect(page).not_to have_content "Cassidy Wilson"
  end
end
