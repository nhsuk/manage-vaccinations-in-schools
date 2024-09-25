# frozen_string_literal: true

describe "Batches" do
  around { |example| travel_to(Time.zone.local(2024, 2, 29)) { example.run } }

  scenario "Adding and editing batches" do
    given_my_team_is_running_an_hpv_vaccination_programme
    and_there_is_a_vaccination_session_today_with_one_patient_ready_to_vaccinate

    when_i_manage_vaccines
    then_i_see_an_hpv_vaccine_with_no_batches_set_up

    when_i_add_a_new_batch
    then_i_see_the_batch_i_just_added_on_the_vaccines_page

    when_i_edit_the_expiry_date_of_the_batch
    then_i_see_the_updated_expiry_date_on_the_vaccines_page
  end

  def given_my_team_is_running_an_hpv_vaccination_programme
    @team = create(:team, :with_one_nurse)
    @programme = create(:programme, :hpv_no_batches, team: @team)
  end

  def and_there_is_a_vaccination_session_today_with_one_patient_ready_to_vaccinate
    location = create(:location, :school)
    session = create(:session, :today, programme: @programme, location:)

    create(:patient_session, :consent_given_triage_not_needed, session:)

    @patient = session.reload.patients.first
  end

  def when_i_manage_vaccines
    sign_in @team.users.first

    visit "/dashboard"
    click_on "Vaccines", match: :first
  end

  def then_i_see_an_hpv_vaccine_with_no_batches_set_up
    expect(page).to have_content("Gardasil 9 (HPV)")
    expect(page).not_to have_css("table")
  end

  def when_i_add_a_new_batch
    click_on "Add a batch", match: :first

    fill_in "Batch", with: "AB1234"

    # expiry date
    fill_in "Day", with: "30"
    fill_in "Month", with: "3"
    fill_in "Year", with: "2024"

    click_on "Add batch"

    expect(page).to have_content("Batch AB1234 added")
  end

  def then_i_see_the_batch_i_just_added_on_the_vaccines_page
    expect(page).to have_content("Gardasil 9 (HPV)")
    expect(page).to have_css("table")
    expect(page).to have_content("AB1234 29 February 202430 March 2024")
  end

  def when_i_edit_the_expiry_date_of_the_batch
    click_on "Change"
    fill_in "Day", with: "31"
    fill_in "Month", with: "3"
    fill_in "Year", with: "2024"
    click_on "Save changes"
  end

  def then_i_see_the_updated_expiry_date_on_the_vaccines_page
    expect(page).to have_content("Gardasil 9 (HPV)")
    expect(page).to have_css("table")
    expect(page).to have_content("AB1234 29 February 202431 March 2024")
  end
end
