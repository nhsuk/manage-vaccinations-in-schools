require "rails_helper"

describe "Patient sorting and filtering" do
  scenario "Users can sort and filter patients" do
    given_that_i_am_signed_in
    when_i_visit_the_consents_page
    then_i_see_patients_ordered_by_name_asc # Initial server load is name asc

    when_i_click_on_the_name_header
    then_i_see_patients_ordered_by_name_asc # On first press still name asc

    when_i_click_on_the_name_header
    then_i_see_patients_ordered_by_name_desc

    when_i_click_on_the_name_header
    then_i_see_patients_ordered_by_name_asc

    when_i_click_on_the_dob_header
    then_i_see_patients_ordered_by_dob_asc

    when_i_click_on_the_dob_header
    then_i_see_patients_ordered_by_dob_desc

    when_i_filter_by_names_starting_with_cas
    and_i_click_filter
    then_i_see_patients_with_names_starting_with_cas_by_dob_desc
    and_by_name_contains_cas

    when_i_click_on_the_name_header
    then_i_see_patients_with_names_starting_with_cas_by_name_asc

    when_i_filter_by_dob_01_2002
    and_i_click_filter
    then_i_see_patients_with_dob_01_2002

    when_i_filter_by_dob_01_01_2002
    and_i_click_filter
    then_i_see_patients_with_dob_01_01_2002
  end

  scenario "Users can sort and filter patients with JS", type: :system do
    given_that_i_am_signed_in
    when_i_visit_the_consents_page
    then_i_see_patients_ordered_by_name_asc
    and_there_should_be_no_filter_button

    2.times { when_i_click_on_the_name_header }
    then_i_see_patients_ordered_by_name_desc

    when_i_filter_by_names_starting_with_cas
    then_i_see_patients_with_names_starting_with_cas_by_name_desc

    when_i_reset_filters
    then_i_see_patients_ordered_by_name_desc
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
        patients_in_session: 4
      )
    @session
      .patients
      .zip(
        %w[Alex Blair Casey Cassidy],
        %w[2000-01-01 2001-01-01 2002-01-01 2002-01-02]
      )
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

  def then_i_see_patients_ordered_by_name_asc
    expect(page).to have_selector("tr:nth-child(1)", text: "Alex")
    expect(page).to have_selector("tr:nth-child(2)", text: "Blair")
    expect(page).to have_selector("tr:nth-child(3)", text: "Casey")
    expect(page).to have_selector("tr:nth-child(4)", text: "Cassidy")
  end
  alias_method :then_i_see_patients_ordered_by_dob_asc,
               :then_i_see_patients_ordered_by_name_asc

  def then_i_see_patients_ordered_by_name_desc
    expect(page).to have_selector("tr:nth-child(1)", text: "Cassidy")
    expect(page).to have_selector("tr:nth-child(2)", text: "Casey")
    expect(page).to have_selector("tr:nth-child(3)", text: "Blair")
    expect(page).to have_selector("tr:nth-child(4)", text: "Alex")
  end
  alias_method :then_i_see_patients_ordered_by_dob_desc,
               :then_i_see_patients_ordered_by_name_desc

  def when_i_filter_by_names_starting_with_cas
    fill_in "By name", with: "cas"
  end

  def and_i_click_filter
    click_button "Filter"
  end

  def and_there_should_be_no_filter_button
    expect(page).not_to have_button "Filter"
  end

  def then_i_see_patients_with_names_starting_with_cas_by_name_desc
    expect(page).not_to have_selector("tr:nth-child(3)")
    expect(page).to have_selector("tr:nth-child(1)", text: "Cassidy")
    expect(page).to have_selector("tr:nth-child(2)", text: "Casey")
  end
  alias_method :then_i_see_patients_with_names_starting_with_cas_by_dob_desc,
               :then_i_see_patients_with_names_starting_with_cas_by_name_desc

  def then_i_see_patients_with_names_starting_with_cas_by_name_asc
    expect(page).not_to have_selector("tr:nth-child(3)")
    expect(page).to have_selector("tr:nth-child(1)", text: "Casey")
    expect(page).to have_selector("tr:nth-child(2)", text: "Cassidy")
  end
  alias_method :then_i_see_patients_with_names_starting_with_cas_by_dob_asc,
               :then_i_see_patients_with_names_starting_with_cas_by_name_asc

  def and_by_name_contains_cas
    expect(page).to have_field("By name", with: "cas")
  end

  def when_i_filter_by_dob_01_2002
    fill_in "By date of birth", with: "01/2002"
  end

  def then_i_see_patients_with_dob_01_2002
    expect(page).not_to have_selector("tr:nth-child(3)")
    expect(page).to have_selector("tr:nth-child(1)", text: "Casey")
    expect(page).to have_selector("tr:nth-child(2)", text: "Cassidy")
  end

  def when_i_filter_by_dob_01_01_2002
    fill_in "By date of birth", with: "01/01/2002"
  end

  def then_i_see_patients_with_dob_01_01_2002
    expect(page).not_to have_selector("tr:nth-child(2)")
    expect(page).to have_selector("tr:nth-child(1)", text: "Casey")
  end

  def when_i_reset_filters
    expect(page).to have_button "Reset filters", disabled: false
    click_button "Reset filters"
  end
end
