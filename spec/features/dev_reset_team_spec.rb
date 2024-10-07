# frozen_string_literal: true

describe "Dev endpoint to reset a team" do
  before { Flipper.enable(:dev_tools) }

  after { Flipper.disable(:dev_tools) }

  scenario "Resetting a team deletes all associated data" do
    given_an_example_programme_exists
    and_patients_have_been_imported
    and_vaccination_records_have_been_imported

    then_all_associated_data_is_deleted_when_i_reset_the_team
  end

  def given_an_example_programme_exists
    @programme = create(:programme, :hpv_all_vaccines, batch_count: 4)
    @team = create(:team, :with_one_nurse, programmes: [@programme])
    @team.update!(ods_code: "R1L") # to match valid_hpv.csv
    @team.schools << create(:location, :school, urn: "123456") # to match cohort_import/valid.csv
    @team.schools << create(:location, :school, urn: "110158") # to match valid_hpv.csv
    @user = @team.users.first
  end

  def and_patients_have_been_imported
    sign_in @user
    visit "/dashboard"
    click_on "Programmes", match: :first
    click_on "HPV"
    click_on "Cohort"
    click_on "Import child records"
    attach_file("cohort_import[csv]", "spec/fixtures/cohort_import/valid.csv")
    click_on "Continue"

    perform_enqueued_jobs
    visit edit_programme_cohort_import_path(@programme, CohortImport.last)

    expect(page).to have_content("Full nameNHS numberDate of birthPostcode")

    click_on "Upload records"

    expect(@team.cohorts.flat_map(&:patients).size).to eq(3)
    expect(@team.cohorts.flat_map(&:patients).flat_map(&:parents).size).to eq(3)
  end

  def and_vaccination_records_have_been_imported
    visit "/dashboard"
    click_on "Programmes", match: :first
    click_on "HPV"
    click_on "Vaccinations"
    click_on "Import vaccination records"
    attach_file(
      "immunisation_import[csv]",
      "spec/fixtures/immunisation_import/valid_hpv.csv"
    )
    click_on "Continue"

    perform_enqueued_jobs
    visit edit_programme_immunisation_import_path(
            @programme,
            ImmunisationImport.last
          )

    click_on "Upload records"
    expect(VaccinationRecord.count).to eq(8)
  end

  def then_all_associated_data_is_deleted_when_i_reset_the_team
    expect { visit "/reset/#{@team.ods_code}" }.to(
      change(Patient, :count)
        .by(-10)
        .and(change(Cohort, :count).by(-2))
        .and(change(Parent, :count).by(-3))
        .and(change(VaccinationRecord, :count).by(-8))
        .and(change(ImmunisationImport, :count).by(-1))
        .and(change(CohortImport, :count).by(-1))
    )
  end
end
