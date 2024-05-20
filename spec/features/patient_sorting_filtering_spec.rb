require "rails_helper"

RSpec.describe "User account" do
  scenario "Users can edit their account details" do
    given_that_i_am_signed_in
    when_i_visit_the_consents_page
    then_i_see_the_list_of_patients_ordered_by_name_asc

    when_i_click_on_the_name_header
    then_i_see_the_list_of_patients_ordered_by_name_asc

    when_i_click_on_the_name_header
    then_i_see_the_list_of_patients_ordered_by_name_desc

    when_i_click_on_the_name_header
    then_i_see_the_list_of_patients_ordered_by_name_asc

    when_i_click_on_the_dob_header
    then_i_see_the_list_of_patients_ordered_by_dob_asc

    when_i_click_on_the_dob_header
    then_i_see_the_list_of_patients_ordered_by_dob_desc

    when_i_click_on_the_dob_header
    then_i_see_the_list_of_patients_ordered_by_dob_asc
  end

  def given_that_i_am_signed_in
    @team = create(:team, :with_one_nurse, :with_one_location)
    @user = @team.users.first
    @campaign = create(:campaign, :hpv, team: @team)
    @session =
      create(
        :session,
        campaign: @campaign,
        location: @team.locations.first,
        patients_in_session: 3
      )
    @session
      .patients
      .zip(%w[Alex Blair Casey], %w[2000-01-01 2000-01-02 2000-01-03])
      .each do |(patient, name, dob)|
        patient.update!(first_name: name, date_of_birth: dob)
      end
    sign_in @user
  end

  def when_i_visit_the_consents_page
    visit session_consents_path(session_id: @session)
  end

  def when_i_click_on_the_name_header
    click_link "Full name"
  end

  def when_i_click_on_the_dob_header
    click_link "Date of birth"
  end

  def then_i_see_the_list_of_patients_ordered_by_name_asc
    expect(page).to have_selector("tr:nth-child(1)", text: "Alex")
    expect(page).to have_selector("tr:nth-child(2)", text: "Blair")
    expect(page).to have_selector("tr:nth-child(3)", text: "Casey")
  end
  alias_method :then_i_see_the_list_of_patients_ordered_by_dob_asc,
               :then_i_see_the_list_of_patients_ordered_by_name_asc

  def then_i_see_the_list_of_patients_ordered_by_name_desc
    expect(page).to have_selector("tr:nth-child(1)", text: "Casey")
    expect(page).to have_selector("tr:nth-child(2)", text: "Blair")
    expect(page).to have_selector("tr:nth-child(3)", text: "Alex")
  end
  alias_method :then_i_see_the_list_of_patients_ordered_by_dob_desc,
               :then_i_see_the_list_of_patients_ordered_by_name_desc
end
