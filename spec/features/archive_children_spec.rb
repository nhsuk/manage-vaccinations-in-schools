# frozen_string_literal: true

describe "Archive children" do
  before do
    given_an_team_exists
    and_i_am_signed_in
  end

  scenario "View archived patients" do
    given_an_unarchived_patient_exists
    and_an_archived_patient_exists

    when_i_visit_the_children_page
    then_i_see_both_patients

    when_i_filter_to_see_only_archived_patients
    then_i_see_only_the_archived_patient
  end

  def given_an_team_exists
    programmes = [create(:programme, :flu)]
    @team = create(:team, programmes:)

    @session = create(:session, team: @team, programmes:)
  end

  def and_i_am_signed_in
    @user = create(:nurse, team: @team)
    sign_in @user
  end

  def given_an_unarchived_patient_exists
    @unarchived_patient = create(:patient, session: @session)
  end

  def and_an_archived_patient_exists
    @archived_patient = create(:patient)
    create(
      :archive_reason,
      :imported_in_error,
      patient: @archived_patient,
      team: @team
    )
  end

  def when_i_visit_the_children_page
    visit patients_path
  end

  def then_i_see_both_patients
    expect(page).to have_content("2 children")
    expect(page).to have_content(@unarchived_patient.full_name)
    expect(page).to have_content(@archived_patient.full_name)
  end

  def when_i_filter_to_see_only_archived_patients
    find(".nhsuk-details__summary").click
    check "Archived records"
    click_on "Search"
  end

  def then_i_see_only_the_archived_patient
    expect(page).to have_content("1 child")
    expect(page).to have_content(@archived_patient.full_name)
  end
end
