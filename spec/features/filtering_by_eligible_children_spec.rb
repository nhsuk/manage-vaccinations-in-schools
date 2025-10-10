# frozen_string_literal: true

describe "Filtering" do
  scenario "By eligible children" do
    given_a_session_exists
    and_patients_are_in_the_session
    and_the_tallying_feature_flag_is_enabled

    when_i_visit_the_session_patients
    then_i_see_all_the_patients

    when_i_filter_eligible_children
    then_i_see_only_the_eligible_patients
  end

  def given_a_session_exists
    @programme = create(:programme, :hpv)
    programmes = [@programme]
    team = create(:team, programmes:)
    @nurse = create(:nurse, team:)
    @session = create(:session, team:, programmes:)
  end

  def and_patients_are_in_the_session
    @patient_eligible = create(:patient, year_group: 8, session: @session)

    @patient_ineligible = create(:patient, year_group: 9, session: @session)

    create(
      :patient_vaccination_status,
      :vaccinated,
      patient: @patient_ineligible,
      programme: @programme,
      academic_year: AcademicYear.current - 1
    )
  end

  def when_i_visit_the_session_patients
    sign_in @nurse
    visit session_patients_path(@session, tallying: true)
  end

  def then_i_see_all_the_patients
    expect(page).to have_content(@patient_eligible.full_name)
    expect(page).to have_content(@patient_ineligible.full_name)
  end

  def then_i_see_only_the_eligible_patients
    expect(page).to have_content(@patient_eligible.full_name)
    expect(page).not_to have_content(@patient_ineligible.full_name)
  end

  def when_i_filter_eligible_children
    check "Eligible children"
    click_on "Update results"
  end

  def and_the_tallying_feature_flag_is_enabled
    Flipper.enable(:tallying)
  end
end
