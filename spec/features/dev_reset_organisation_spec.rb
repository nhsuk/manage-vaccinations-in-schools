# frozen_string_literal: true

describe "Dev endpoint to reset a organisation" do
  before { Flipper.enable(:dev_tools) }
  after { Flipper.disable(:dev_tools) }

  scenario "Resetting a organisation deletes all associated data" do
    given_an_example_programme_exists
    and_patients_have_been_imported
    and_vaccination_records_have_been_imported
    and_emails_have_been_sent
    and_consent_exists
    and_school_moves_exist

    then_all_associated_data_is_deleted_when_i_reset_the_organisation
  end

  def given_an_example_programme_exists
    @programme = create(:programme, :hpv_all_vaccines)
    @organisation =
      create(:organisation, :with_one_nurse, programmes: [@programme])

    @programme.vaccines.each do |vaccine|
      create_list(:batch, 4, organisation: @organisation, vaccine:)
    end

    @organisation.update!(ods_code: "R1L") # to match valid_hpv.csv
    create(:school, urn: "123456", organisation: @organisation) # to match cohort_import/valid.csv
    create(:school, urn: "110158", organisation: @organisation) # to match valid_hpv.csv
    @user = @organisation.users.first
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

    @patients = @organisation.patients.includes(:parents)

    expect(@patients.size).to eq(3)
    expect(@patients.flat_map(&:parents).size).to eq(3)
  end

  def and_vaccination_records_have_been_imported
    visit "/dashboard"
    click_on "Programmes", match: :first
    click_on "HPV"
    click_on "Vaccinations", match: :first
    click_on "Import vaccination records"
    attach_file(
      "immunisation_import[csv]",
      "spec/fixtures/immunisation_import/valid_hpv.csv"
    )
    click_on "Continue"

    expect(VaccinationRecord.count).to eq(11)
  end

  def and_emails_have_been_sent
    @patients.each do |patient|
      create(:notify_log_entry, :email, patient:, consent_form: nil)
    end
  end

  def and_consent_exists
    @patients.each do |patient|
      consent_form = create(:consent_form, session: Session.first)
      parent =
        patient.parents.first || create(:parent_relationship, patient:).parent
      create(
        :consent,
        :given,
        patient:,
        parent:,
        consent_form:,
        programme: @programme
      )
    end
  end

  def and_school_moves_exist
    create(:school_move, :to_school, patient: @patients.first)
  end

  def then_all_associated_data_is_deleted_when_i_reset_the_organisation
    expect { visit "/reset/r1l" }.to(
      change(CohortImport, :count)
        .by(-1)
        .and(change(ImmunisationImport, :count).by(-1))
        .and(change(NotifyLogEntry, :count).by(-3))
        .and(change(Parent, :count).by(-4))
        .and(change(Patient, :count).by(-3))
        .and(change(PatientSession, :count).by(-3))
        .and(change(VaccinationRecord, :count).by(-11))
    )
  end
end
