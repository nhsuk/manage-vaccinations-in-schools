# frozen_string_literal: true

describe "Triage" do
  scenario "can triage even if not required" do
    given_an_mmr_session_exists
    and_a_patient_exists_with_consent_and_triage_not_required

    when_i_visit_the_session
    and_i_go_to_the_patient
    then_i_can_update_their_triage_outcome

    when_i_update_their_triage_outcome
    then_i_see_the_new_triage_status
  end

  def given_an_mmr_session_exists
    programmes = [create(:programme, :mmr)]
    team = create(:team, programmes:)

    @user = create(:nurse, teams: [team])
    @session = create(:session, programmes:, team:)
  end

  def and_a_patient_exists_with_consent_and_triage_not_required
    @patient =
      create(:patient, :consent_given_triage_not_needed, session: @session)
  end

  def when_i_visit_the_session
    sign_in @user
    visit session_path(@session)
  end

  def and_i_go_to_the_patient
    within(".app-secondary-navigation") { click_on "Children" }
    click_on @patient.full_name
  end

  def then_i_can_update_their_triage_outcome
    expect(page).not_to have_content("Safe to vaccinate")
    expect(page).to have_content(
      "No triage is needed for #{@patient.full_name}"
    )
    expect(page).to have_link("Update triage outcome")
  end

  def when_i_update_their_triage_outcome
    click_on "Update triage outcome"
    choose "Yes, it’s safe to vaccinate"
    click_on "Save triage"
  end

  def then_i_see_the_new_triage_status
    expect(page).to have_content("Safe to vaccinate")
  end
end
