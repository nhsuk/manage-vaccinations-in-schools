# frozen_string_literal: true

describe "Vaccination programmes table" do
  around { |example| travel_to(Date.new(2025, 8, 31)) { example.run } }

  before { given_my_team_exists }

  scenario "patient has non-seasonal vaccine" do
    given_patients_exist_in_year_eleven
    and_the_patient_is_vaccinated_for_hpv

    when_i_click_on_children
    and_i_click_on_a_child

    then_the_table_has_a_row_showing_hpv_vaccinated
    and_the_table_shows_other_eligible_vaccinations
  end

  scenario "patient has non-seasonal vaccine with more than one dose" do
    given_patients_exist_in_year_eleven
    and_the_patient_is_vaccinated_for_hpv
    and_the_patient_has_a_second_dose_of_hpv

    when_i_click_on_children
    and_i_click_on_a_child

    then_the_table_has_a_row_showing_hpv_vaccinated
    and_the_table_has_a_row_showing_second_hpv_vaccinated
  end

  def given_my_team_exists
    @programmes = [
      @flu_programme = create(:programme, :flu),
      @hpv_programme = create(:programme, :hpv),
      @menacwy_programme = create(:programme, :menacwy),
      @td_ipv_programme = create(:programme, :td_ipv)
    ]

    @team = create(:team, :with_one_nurse, programmes: @programmes)
  end

  def given_patients_exist_in_year_eleven
    school = create(:school, team: @team)

    @session =
      create(:session, location: school, team: @team, programmes: @programmes)

    @patient =
      create(
        :patient,
        session: @session,
        year_group: 10,
        given_name: "John",
        family_name: "Smith",
        programmes: @programmes,
        school:
      )
  end

  def when_i_click_on_children
    sign_in @team.users.first

    visit "/dashboard"
    click_on "Children", match: :first
  end

  def and_i_click_on_a_child
    click_on "SMITH, John"
  end

  def then_the_table_has_a_row_showing_hpv_vaccinated
    expect(page).to have_selector(
      "table.nhsuk-table tbody tr",
      text: "HPV"
    ) do |row|
      expect(row).to have_selector("td.nhsuk-table__cell", text: "Vaccinated")
    end
  end

  def and_the_table_has_a_row_showing_second_hpv_vaccinated
    expect(page).to have_selector(
      "table.nhsuk-table tbody tr",
      text: "HPV (2nd dose)"
    ) do |row|
      expect(row).to have_selector("td.nhsuk-table__cell", text: "Vaccinated")
    end
  end

  def and_the_table_shows_other_eligible_vaccinations
    expect(page).to have_selector(
      "table.nhsuk-table tbody tr",
      text: "Flu (Winter 2025)"
    ) do |row|
      expect(row).to have_selector(
        "td.nhsuk-table__cell",
        text: "Eligibility starts 1 September 2025"
      )
    end

    expect(page).to have_selector(
      "table.nhsuk-table tbody tr",
      text: "MenACWY"
    ) do |row|
      expect(row).to have_selector(
        "td.nhsuk-table__cell",
        text: "Eligibility started 1 September 2023"
      )
    end
  end

  def and_the_patient_is_vaccinated_for_hpv
    create(
      :vaccination_record,
      patient: @patient,
      programme: @hpv_programme,
      session: @session,
      performed_at: 6.months.ago
    )
  end

  def and_the_patient_has_a_second_dose_of_hpv
    create(
      :vaccination_record,
      dose_sequence: 2,
      patient: @patient,
      programme: @hpv_programme,
      session: @session
    )
  end
end
