# frozen_string_literal: true

describe "Download school moves" do
  scenario "no dates given" do
    given_i_am_signed_in
    and_school_moves_exist
    and_i_go_school_moves
    when_i_click_on_download_records
    and_i_click_continue
    then_i_should_see_a_confirmation_page
    when_i_click_download_csv
    then_i_get_a_csv_file_with_expected_row_count(2)
  end

  scenario "dates supplied" do
    given_i_am_signed_in
    and_school_moves_exist
    and_i_go_school_moves
    when_i_click_on_download_records
    when_i_enter_some_dates
    then_i_should_see_a_confirmation_page_with_dates
    when_i_click_download_csv
    then_i_get_a_csv_file_with_expected_row_count(1)
  end

  def given_i_am_signed_in
    team = create(:team, :with_one_nurse)
    @session = create(:session, team:)
    @patients =
      create_list(
        :patient,
        2,
        :consent_given_triage_not_needed,
        :in_attendance,
        session: @session
      )

    sign_in team.users.first
  end

  def and_school_moves_exist
    create(
      :school_move_log_entry,
      patient: @patients.first,
      school: @session.location
    )
    create(
      :school_move_log_entry,
      patient: @patients.second,
      school: @session.location,
      created_at: Time.zone.local(2024, 6, 15) # Middle of the date range
    )
  end

  def and_i_go_school_moves
    visit school_moves_path
  end

  def when_i_click_on_download_records
    click_on "Download records"
  end

  def and_i_click_continue
    click_on "Continue"
  end

  def when_i_click_download_csv
    click_on "Download CSV"
  end

  def then_i_get_a_csv_file_with_expected_row_count(expected_count)
    expect(page).to have_content(
      Reports::SchoolMovesExporter::HEADERS.join(",")
    )
    csv_content = CSV.parse(page.body, headers: true)
    expect(csv_content.size).to eq(expected_count)
  end

  def when_i_enter_some_dates
    within all(".nhsuk-fieldset")[0] do
      fill_in "Day", with: "01"
      fill_in "Month", with: "01"
      fill_in "Year", with: "2024"
    end

    within all(".nhsuk-fieldset")[1] do
      fill_in "Day", with: "31"
      fill_in "Month", with: "12"
      fill_in "Year", with: "2024"
    end

    click_on "Continue"
  end

  def then_i_should_see_a_confirmation_page
    check_summary_list_row("From", "Earliest recorded vaccination")
    check_summary_list_row("Until", "Latest recorded vaccination")
    check_summary_list_row("Records", "2")
  end

  def then_i_should_see_a_confirmation_page_with_dates
    check_summary_list_row("From", "01 January 2024")
    check_summary_list_row("Until", "31 December 2024")
    check_summary_list_row("Records", "1")
  end

  def check_summary_list_row(key, value)
    within(".nhsuk-summary-list") do
      expect(page).to have_css(".nhsuk-summary-list__key", text: key)
      expect(page).to have_css(".nhsuk-summary-list__value", text: value)
    end
  end
end
