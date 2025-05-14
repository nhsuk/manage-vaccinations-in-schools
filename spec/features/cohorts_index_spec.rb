# frozen_string_literal: true

describe "Cohorts index" do
  around { |example| travel_to(Date.new(2024, 5, 20)) { example.run } }

  scenario "Viewing cohorts for a programme" do
    given_an_hpv_programme_is_underway
    and_there_are_patients_in_different_year_groups
    when_i_visit_the_cohorts_page
    then_i_should_see_the_cohorts_in_the_correct_order
    and_i_should_see_the_correct_patient_counts
    and_the_cards_should_be_clickable_when_there_are_patients
    and_the_cards_should_not_be_clickable_when_there_are_no_patients
  end

  def given_an_hpv_programme_is_underway
    @programme = create(:programme, :hpv)
    @organisation =
      create(:organisation, :with_one_nurse, programmes: [@programme])
    sign_in @organisation.users.first
  end

  def and_there_are_patients_in_different_year_groups
    # Create patients in year 8 and 9
    # For year 8 in 2024, birth academic year is 2010
    # For year 9 in 2024, birth academic year is 2009
    create(
      :patient,
      organisation: @organisation,
      date_of_birth: Date.new(2009, 9, 1)
    )
    create(
      :patient,
      organisation: @organisation,
      date_of_birth: Date.new(2009, 9, 1)
    )
    create(
      :patient,
      organisation: @organisation,
      date_of_birth: Date.new(2008, 9, 1)
    )
  end

  def when_i_visit_the_cohorts_page
    visit "/dashboard"
    click_on "Programmes", match: :first
    click_on "HPV"
    click_on "Cohort"
  end

  def then_i_should_see_the_cohorts_in_the_correct_order
    # Get all the cohort cards and check their order
    cohort_cards = page.all(".nhsuk-card-group__item")
    expect(cohort_cards[0]).to have_content("Year 8")
    expect(cohort_cards[1]).to have_content("Year 9")
    expect(cohort_cards[2]).to have_content("Year 10")
    expect(cohort_cards[3]).to have_content("Year 11")
  end

  def and_i_should_see_the_correct_patient_counts
    expect(page).to have_content("Year 8\nNo children")
    expect(page).to have_content("Year 9\n2 children")
    expect(page).to have_content("Year 10\n1 child")
    expect(page).to have_content("Year 11\nNo children")
  end

  def and_the_cards_should_be_clickable_when_there_are_patients
    # Year 9 and 10 cards should be clickable
    expect(page).to have_link(
      "Year 9",
      href: programme_cohort_path(@programme, 2009)
    )
    expect(page).to have_link(
      "Year 10",
      href: programme_cohort_path(@programme, 2008)
    )
  end

  def and_the_cards_should_not_be_clickable_when_there_are_no_patients
    # Year 8 and 11 cards should not be clickable
    expect(page).not_to have_link(
      "Year 8",
      href: programme_cohort_path(@programme, 2010)
    )
    expect(page).not_to have_link(
      "Year 11",
      href: programme_cohort_path(@programme, 2007)
    )
  end
end
