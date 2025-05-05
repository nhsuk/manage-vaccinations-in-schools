# frozen_string_literal: true

describe "Filtering" do
  around { |example| travel_to(Time.zone.local(2024, 2, 1)) { example.run } }

  scenario "By programme" do
    given_a_session_exists
    and_patients_are_in_the_session

    when_i_visit_the_session_outcomes
    then_i_see_all_the_patients
    and_i_see_all_the_statuses

    when_i_filter_on_hpv
    then_i_see_all_the_patients
    and_i_see_only_the_hpv_statuses

    when_i_filter_on_menacwy
    then_i_see_only_patients_eligible_for_menacwy
    and_i_see_only_the_menacwy_statuses
  end

  def given_a_session_exists
    programmes = [create(:programme, :hpv), create(:programme, :menacwy)]

    organisation = create(:organisation, programmes:)
    @nurse = create(:nurse, organisation:)

    @session = create(:session, organisation:, programmes:)
  end

  def and_patients_are_in_the_session
    @patient_eligible_for_hpv =
      create(:patient, year_group: 8, session: @session)

    @patient_eligible_for_hpv_and_menacwy =
      create(:patient, year_group: 9, session: @session)
  end

  def when_i_visit_the_session_outcomes
    sign_in @nurse
    visit session_outcome_path(@session)
  end

  def then_i_see_all_the_patients
    expect(page).to have_content(@patient_eligible_for_hpv.full_name)
    expect(page).to have_content(
      @patient_eligible_for_hpv_and_menacwy.full_name
    )
  end

  def and_i_see_all_the_statuses
    expect(page).to have_content("HPVNo outcome yet").twice
    expect(page).to have_content("MenACWYNo outcome yet").once
  end

  def when_i_filter_on_hpv
    check "HPV"
    click_on "Update results"
  end

  def and_i_see_only_the_hpv_statuses
    expect(page).to have_content("HPVNo outcome yet").twice
    expect(page).not_to have_content("MenACWYNo outcome yet")
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
    expect(page).not_to have_content("HPVNo outcome yet")
    expect(page).to have_content("MenACWYNo outcome yet").once
  end
end
