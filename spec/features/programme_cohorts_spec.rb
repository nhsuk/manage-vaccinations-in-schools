# frozen_string_literal: true

describe "Programme" do
  around { |example| travel_to(Date.new(2024, 5, 20)) { example.run } }

  scenario "Viewing cohorts" do
    given_an_hpv_programme_is_underway
    and_there_are_patients_in_different_year_groups

    when_i_visit_the_overview_page
    then_i_should_see_the_cohorts_in_the_correct_order
    and_i_should_see_the_correct_patient_counts
    and_the_cards_should_be_clickable_when_there_are_patients
    and_the_cards_should_not_be_clickable_when_there_are_no_patients

    when_i_click_on_the_year_9_cohort
    then_i_see_the_patients_in_year_9
  end

  scenario "patient is not counted for a session if their year group is not eligible" do
    given_a_school_has_separate_sessions_for_different_year_groups
    and_a_patient_is_only_eligible_for_only_one_of_those_sessions

    when_i_visit_the_sessions_page
    then_the_ineligible_session_should_show_no_children
    and_the_eligible_session_should_show_one_child
  end

  def given_an_hpv_programme_is_underway
    @academic_year = AcademicYear.current
    @programme = Programme.hpv
    @team =
      create(
        :team,
        :with_one_nurse,
        :with_generic_clinic,
        programmes: [@programme]
      )

    sign_in @team.users.first
  end

  def and_there_are_patients_in_different_year_groups
    session = create(:session, team: @team, programmes: [@programme])

    @patient1 = create(:patient, session:, year_group: 9)
    @patient2 = create(:patient, session:, year_group: 9)
    create(:patient, session:, year_group: 10)

    # To make it realistic we'll also add patients to clinics.
    Patient.find_each do |patient|
      create(
        :patient_location,
        patient:,
        session:
          @team.generic_clinic_session(academic_year: AcademicYear.current)
      )
    end
  end

  def given_a_school_has_separate_sessions_for_different_year_groups
    td_ipv_programme = Programme.td_ipv
    hpv_programme = Programme.hpv

    @academic_year = AcademicYear.current
    @location =
      location = create(:school, programmes: [td_ipv_programme, hpv_programme])

    team =
      create(
        :team,
        :with_one_nurse,
        programmes: [td_ipv_programme, hpv_programme]
      )

    create(:session, team:, location:, programmes: [td_ipv_programme])
    create(:session, team:, location:, programmes: [hpv_programme])

    sign_in team.users.first
  end

  def and_a_patient_is_only_eligible_for_only_one_of_those_sessions
    create(
      :patient_location,
      patient: create(:patient, year_group: 8),
      location: @location,
      academic_year: @academic_year
    )
  end

  def then_the_ineligible_session_should_show_no_children
    card = page.find("dd", text: "Td/IPV").ancestor(".nhsuk-card")

    expect(card).to have_content("No children")
  end

  def and_the_eligible_session_should_show_one_child
    card = page.find("dd", text: "HPV").ancestor(".nhsuk-card")

    expect(card).to have_content("1 child")
  end

  def when_i_visit_the_overview_page
    visit "/dashboard"
    click_on "Programmes", match: :first
    click_on "HPV"
  end

  def when_i_visit_the_sessions_page
    visit sessions_path
  end

  def then_i_should_see_the_cohorts_in_the_correct_order
    # Get all the cohort cards and check their order
    cohort_cards = page.all(".nhsuk-card-group__item")

    # First 3 cards contain statistics
    expect(cohort_cards[3]).to have_content("Year 8")
    expect(cohort_cards[4]).to have_content("Year 9")
    expect(cohort_cards[5]).to have_content("Year 10")
    expect(cohort_cards[6]).to have_content("Year 11")
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
      href:
        programme_patients_path(@programme, @academic_year, year_groups: [9])
    )
    expect(page).to have_link(
      "Year 10",
      href:
        programme_patients_path(@programme, @academic_year, year_groups: [10])
    )
  end

  def and_the_cards_should_not_be_clickable_when_there_are_no_patients
    # Year 8 and 11 cards should not be clickable
    expect(page).not_to have_link("Year 8")
    expect(page).not_to have_link("Year 11")
  end

  def when_i_click_on_the_year_9_cohort
    click_on "Year 9"
  end

  def then_i_see_the_patients_in_year_9
    expect(page).to have_content(@patient1.full_name).once
    expect(page).to have_content(@patient2.full_name).once
  end
end
