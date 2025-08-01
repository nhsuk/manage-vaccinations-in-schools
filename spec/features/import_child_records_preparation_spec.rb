# frozen_string_literal: true

describe "Import child records" do
  around { |example| travel_to(Date.new(2022, 8, 1)) { example.run } }

  scenario "User uploads a file during preparation period" do
    given_the_app_is_setup
    then_i_should_be_in_the_preparation_period

    when_i_visit_the_import_page
    and_i_choose_to_import_child_records
    then_i_should_see_the_import_page

    when_i_upload_a_valid_file
    then_i_should_see_the_upload
    and_i_should_see_the_patients

    when_i_visit_the_hpv_programme_page
    then_i_should_see_the_cohorts_for_hpv

    when_i_click_on_the_cohort_for_hpv
    then_i_should_see_the_children_for_hpv

    when_i_search_for_a_child
    then_i_should_see_only_the_child

    when_i_visit_the_doubles_programme_page
    then_i_should_see_the_cohorts_for_doubles

    when_i_click_on_the_cohort_for_doubles
    then_i_should_see_the_children_for_doubles

    when_i_click_on_the_imports_page
    and_i_choose_to_import_child_records
    then_i_should_see_the_import_page
  end

  def given_the_app_is_setup
    programmes = [
      create(:programme, :hpv),
      create(:programme, :menacwy),
      create(:programme, :td_ipv)
    ]

    @organisation =
      create(:organisation, :with_generic_clinic, :with_one_nurse, programmes:)
    create(:school, urn: "123456", organisation: @organisation)
    @user = @organisation.users.first

    [AcademicYear.current, AcademicYear.pending].each do |academic_year|
      OrganisationSessionsFactory.call(@organisation, academic_year:)
    end
  end

  def then_i_should_be_in_the_preparation_period
    expect(AcademicYear.pending).to be > AcademicYear.current
  end

  def when_i_visit_the_import_page
    sign_in @user
    visit "/dashboard"
    click_on "Import", match: :first
  end

  def and_i_choose_to_import_child_records
    click_on "Import records"
    choose "Child records"
    click_on "Continue"
  end

  def then_i_should_see_the_import_page
    expect(page).to have_content("Import child records")
  end

  def when_i_upload_a_valid_file
    attach_file("cohort_import[csv]", "spec/fixtures/cohort_import/valid.csv")
    click_on "Continue"
  end

  def then_i_should_see_the_patients
    expect(page).to have_content(
      "Name and NHS numberPostcodeSchoolDate of birth"
    )
    expect(page).to have_content("SMITH, Jimmy")
    expect(page).to have_content(/NHS number.*999.*000.*0018/)
    expect(page).to have_content("Date of birth 1 January 2010")
    expect(page).to have_content("Postcode SW1A 1AA")
  end

  alias_method :and_i_should_see_the_patients, :then_i_should_see_the_patients

  def when_i_click_on_upload_records
    click_on "Upload records"
  end

  def then_i_should_see_the_upload
    expect(page).to have_content("Imported on")
    expect(page).to have_content("Imported byUSER, Test")
  end

  def when_i_click_on_the_imports_page
    click_on "Import", match: :first
  end

  def then_i_should_see_the_import
    expect(page).to have_content("1 completed import")
  end

  def when_i_visit_the_hpv_programme_page
    click_on "Programmes", match: :first

    within all(".nhsuk-table__panel-with-heading-tab").first do
      click_on "HPV"
    end
  end

  def when_i_visit_the_doubles_programme_page
    click_on "Programmes", match: :first

    within all(".nhsuk-table__panel-with-heading-tab").first do
      click_on "MenACWY"
    end
  end

  def then_i_should_see_the_cohorts_for_hpv
    expect(page).to have_content("Children\n3")
    expect(page).to have_content("Year 8\n2 children")
    expect(page).to have_content("Year 9\n1 child")
    expect(page).to have_content("Year 10\nNo children")
    expect(page).to have_content("Year 11\nNo children")
  end

  def when_i_click_on_the_cohort_for_hpv
    click_on "Year 8"
  end

  def then_i_should_see_the_children_for_hpv
    expect(page).to have_content("2 children")
    expect(page).to have_content("DOE, Mark")
    expect(page).to have_content("SMITH, Jimmy")
  end

  def when_i_search_for_a_child
    fill_in "Search", with: "DOE, Mark"
    click_on "Search"
  end

  def then_i_should_see_only_the_child
    expect(page).to have_content("1 child")
    expect(page).to have_content("DOE, Mark")
  end

  def then_i_should_see_the_cohorts_for_doubles
    expect(page).to have_content("Children\n1")
    expect(page).not_to have_content("Year 8")
    expect(page).to have_content("Year 9\n1 child")
    expect(page).to have_content("Year 10\nNo children")
    expect(page).to have_content("Year 11\nNo children")
  end

  def when_i_click_on_the_cohort_for_doubles
    within all(".nhsuk-card")[0] do
      click_on "Children"
    end
  end

  def then_i_should_see_the_children_for_doubles
    expect(page).to have_content("1 child")
    expect(page).to have_content("CLARKE, Jennifer")
    expect(page).to have_content("Year 9 (2022 to 2023 academic year)")
  end
end
