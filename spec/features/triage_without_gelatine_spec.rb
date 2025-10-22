# frozen_string_literal: true

describe "Triage" do
  before do
    given_an_mmr_programme_is_underway
    given_a_patient_exists_needing_triage
  end

  scenario "safe to vaccinate with gelatine" do
    given_a_patient_exists_needing_triage

    when_i_go_to_the_session_triage_tab
    then_i_see_the_patient

    when_i_click_on_the_patient
    then_i_see_the_triage_options

    when_i_record_the_triage_outcome(without_gelatine: false)
    then_i_see_the_triage_status_with_gelatine
  end

  scenario "safe to vaccinate without gelatine" do
    given_a_patient_exists_needing_triage

    when_i_go_to_the_session_triage_tab
    then_i_see_the_patient

    when_i_click_on_the_patient
    then_i_see_the_triage_options

    when_i_record_the_triage_outcome(without_gelatine: true)
    then_i_see_the_triage_status_without_gelatine
  end

  scenario "safe to vaccinate without gelatine only" do
    given_a_patient_exists_needing_triage_without_gelatine

    when_i_go_to_the_session_triage_tab
    then_i_see_the_patient

    when_i_click_on_the_patient
    then_i_see_the_triage_options_without_gelatine_only

    when_i_record_the_triage_outcome(without_gelatine: true)
    then_i_see_the_triage_status_without_gelatine
  end

  def given_an_mmr_programme_is_underway
    programmes = [create(:programme, :mmr)]

    team = create(:team, programmes:)
    @user = create(:nurse, team:)

    @session = create(:session, team:, programmes:)
  end

  def given_a_patient_exists_needing_triage
    @patient = create(:patient, :consent_given_triage_needed, session: @session)
  end

  def given_a_patient_exists_needing_triage_without_gelatine
    @patient =
      create(
        :patient,
        :consent_given_without_gelatine_triage_needed,
        session: @session
      )
  end

  def when_i_go_to_the_session_triage_tab
    sign_in @user
    visit session_triage_path(@session)
  end

  def then_i_see_the_patient
    expect(page).to have_content(@patient.full_name)
    expect(page).to have_content("MMRNeeds triage")
  end

  def when_i_click_on_the_patient
    click_on @patient.full_name
  end

  def then_i_see_the_triage_options
    expect(page).to have_content("Yes, it’s safe to vaccinate").twice
    expect(page).to have_content(
      "Yes, it’s safe to vaccinate with the gelatine-free vaccine"
    )
  end

  def then_i_see_the_triage_options_without_gelatine_only
    expect(page).to have_content("Yes, it’s safe to vaccinate").once
    expect(page).to have_content(
      "Yes, it’s safe to vaccinate with the gelatine-free vaccine"
    )
  end

  def when_i_record_the_triage_outcome(without_gelatine:)
    if without_gelatine
      choose "Yes, it’s safe to vaccinate with the gelatine-free vaccine"
    else
      choose "Yes, it’s safe to vaccinate"
    end
    click_on "Save triage"
  end

  def then_i_see_the_triage_status_with_gelatine
    expect(page).to have_content("MMR: Safe to vaccinate")
  end

  def then_i_see_the_triage_status_without_gelatine
    expect(page).to have_content(
      "MMR: Safe to vaccinate with gelatine-free vaccine"
    )
  end
end
