# frozen_string_literal: true

describe "Filtering" do
  around { |example| travel_to(Time.zone.local(2024, 2, 1)) { example.run } }

  scenario "By programme" do
    given_a_session_exists_with_programmes(%w[hpv menacwy])
    and_patients_are_in_the_session

    when_i_visit_the_session_patients
    then_i_see_all_the_patients
    and_i_see_all_the_statuses

    when_i_filter_on_hpv
    then_i_see_all_the_patients
    and_i_see_only_the_hpv_statuses

    when_i_filter_on_menacwy
    then_i_see_only_patients_eligible_for_menacwy
    and_i_see_only_the_menacwy_statuses
  end

  scenario "By year group" do
    given_a_session_exists_with_programmes(%w[hpv])
    and_patients_are_in_the_session

    when_i_visit_the_session_patients
    and_i_filter_on_year_group_eight
    the_i_should_only_see_patients_for_year_eight
  end

  scenario "With only one programme in session" do
    given_a_session_exists_with_programmes(%w[hpv])
    and_patients_are_in_the_session

    when_i_visit_the_session_patients
    then_i_see_all_the_patients
    and_i_dont_see_programme_filter_checkboxes
    and_i_see_only_hpv_statuses_for_all_patients
  end

  def given_a_session_exists_with_programmes(programme_types)
    programmes = programme_types.map { Programme.find(it) }
    team = create(:team, programmes:)
    @nurse = create(:nurse, team:)
    @session = create(:session, team:, programmes:)
  end

  def and_patients_are_in_the_session
    @patient_eligible_for_hpv =
      create(:patient, year_group: 8, session: @session)

    @patient_eligible_for_hpv_and_menacwy =
      create(:patient, year_group: 9, session: @session)
  end

  def when_i_visit_the_session_patients
    sign_in @nurse
    visit session_patients_path(@session)
  end

  def then_i_see_all_the_patients
    expect(page).to have_content(@patient_eligible_for_hpv.full_name)
    expect(page).to have_content(
      @patient_eligible_for_hpv_and_menacwy.full_name
    )
  end

  def and_i_see_all_the_statuses
    expect(page).to have_content("HPVNot eligible").exactly(2).times
    expect(page).to have_content("MenACWYNot eligible").once
  end

  def and_i_dont_see_programme_filter_checkboxes
    expect(page).not_to have_field("HPV", type: "checkbox")
    expect(page).not_to have_field("MenACWY", type: "checkbox")
  end

  def and_i_see_only_hpv_statuses_for_all_patients
    expect(page).to have_content("HPVNot eligible").exactly(2).times
    expect(page).not_to have_content("MenACWYNot eligible")
  end

  def when_i_filter_on_hpv
    check "HPV"
    click_on "Update results"
  end

  def and_i_see_only_the_hpv_statuses
    expect(page).to have_content("HPVNot eligible").exactly(2).times
    expect(page).not_to have_content("MenACWYNot eligible")
  end

  def when_i_filter_on_menacwy
    uncheck "HPV"
    check "MenACWY"
    click_on "Update results"
  end

  def then_i_see_only_patients_eligible_for_menacwy
    expect(page).not_to have_content(@patient_eligible_for_hpv.full_name)
    expect(page).to have_content(
      @patient_eligible_for_hpv_and_menacwy.full_name
    )
  end

  def and_i_see_only_the_menacwy_statuses
    expect(page).not_to have_content("HPVNot eligible")
    expect(page).to have_content("MenACWYNot eligible").once
  end

  def and_i_filter_on_year_group_eight
    check "Year 8"
    click_on "Update results"
  end

  def the_i_should_only_see_patients_for_year_eight
    expect(page).to have_content(@patient_eligible_for_hpv.full_name)
    expect(page).not_to have_content(
      @patient_eligible_for_hpv_and_menacwy.full_name
    )
  end
end
