# frozen_string_literal: true

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

    when_i_click_on_the_year_group_header
    then_i_see_patients_ordered_by_year_group_asc

    when_i_click_on_the_year_group_header
    then_i_see_patients_ordered_by_year_group_desc

    when_i_filter_by_names_starting_with_cas
    and_i_click_filter
    then_i_see_patients_with_names_starting_with_cas_by_year_group_desc
    and_by_name_contains_cas

    when_i_click_on_the_name_header
    then_i_see_patients_with_names_starting_with_cas_by_name_asc

    when_i_filter_by_year_group_10
    and_i_click_filter
    then_i_see_patients_with_year_group_10
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
    @programme = create(:programme, :hpv)
    @organisation =
      create(:organisation, :with_one_nurse, programmes: [@programme])
    location = create(:location, :school)
    @user = @organisation.users.first
    @session =
      create(
        :session,
        organisation: @organisation,
        programme: @programme,
        location:
      )

    %w[Alex Blair Casey Cassidy]
      .zip([8, 9, 10, 10], %w[A B C D])
      .each do |(given_name, year_group, registration)|
        create(
          :patient,
          session: @session,
          given_name:,
          year_group:,
          registration:
        )
      end

    sign_in @user
  end

  def when_i_visit_the_consents_page
    visit session_consents_path(@session)
  end

  def when_i_click_on_the_name_header
    click_link "Full name"
    sleep 0.1
  end

  def when_i_click_on_the_year_group_header
    click_link "Year group"
  end

  def then_i_see_patients_ordered_by_name_asc
    expect(page).to have_selector("tr:nth-child(1)", text: "Alex")
    expect(page).to have_selector("tr:nth-child(2)", text: "Blair")
    expect(page).to have_selector("tr:nth-child(3)", text: "Casey")
    expect(page).to have_selector("tr:nth-child(4)", text: "Cassidy")
  end
  alias_method :then_i_see_patients_ordered_by_year_group_asc,
               :then_i_see_patients_ordered_by_name_asc

  def then_i_see_patients_ordered_by_name_desc
    expect(page).to have_selector("tr:nth-child(1)", text: "Cassidy")
    expect(page).to have_selector("tr:nth-child(2)", text: "Casey")
    expect(page).to have_selector("tr:nth-child(3)", text: "Blair")
    expect(page).to have_selector("tr:nth-child(4)", text: "Alex")
  end
  alias_method :then_i_see_patients_ordered_by_year_group_desc,
               :then_i_see_patients_ordered_by_name_desc

  def when_i_filter_by_names_starting_with_cas
    fill_in "Name", with: "cas"
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
  alias_method :then_i_see_patients_with_names_starting_with_cas_by_year_group_desc,
               :then_i_see_patients_with_names_starting_with_cas_by_name_desc

  def then_i_see_patients_with_names_starting_with_cas_by_name_asc
    expect(page).not_to have_selector("tr:nth-child(3)")
    expect(page).to have_selector("tr:nth-child(1)", text: "Casey")
    expect(page).to have_selector("tr:nth-child(2)", text: "Cassidy")
  end
  alias_method :then_i_see_patients_with_names_starting_with_cas_by_year_group_asc,
               :then_i_see_patients_with_names_starting_with_cas_by_name_asc

  def and_by_name_contains_cas
    expect(page).to have_field("Name", with: "cas")
  end

  def when_i_filter_by_year_group_10
    check "Year 10"
  end

  def then_i_see_patients_with_year_group_10
    expect(page).not_to have_selector("tr:nth-child(3)")
    expect(page).to have_selector("tr:nth-child(1)", text: "Casey")
    expect(page).to have_selector("tr:nth-child(2)", text: "Cassidy")
  end

  def when_i_reset_filters
    expect(page).to have_button "Reset filters", disabled: false
    click_button "Reset filters"
  end
end
