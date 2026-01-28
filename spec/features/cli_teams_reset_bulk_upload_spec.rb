# frozen_string_literal: true

describe "mavis teams reset-bulk-upload" do
  around { |example| travel_to(Date.new(2025, 12, 20)) { example.run } }

  let(:bulk_organisation) { create(:organisation, ods_code: "R1L") }
  let(:poc_organisation) { create(:organisation) }

  context "when sync_national_reporting_to_imms_api feature flag is enabled" do
    it "does not allow resetting bulk upload teams" do
      given_a_bulk_upload_team_exists
      and_the_feature_flag_is_enabled
      and_the_bulk_upload_team_has_immunisation_imports_with_vaccination_records

      when_i_run_the_command_for_single_team

      then_an_error_is_displayed_in_output
      and_no_immunisation_imports_are_deleted
      and_no_vaccination_records_are_deleted
      and_no_patients_are_deleted
    end
  end

  context "when resetting a single bulk upload team" do
    it "removes all immunisation imports, associated vaccination records, and associated patients" do
      given_a_bulk_upload_team_exists
      and_i_upload_some_vaccination_records

      when_i_run_the_command_for_single_team

      then_all_the_immunisation_imports_are_deleted
      and_all_the_vaccination_records_are_deleted
      and_all_the_archive_reasons_are_deleted
      and_all_the_patients_are_deleted
    end

    it "updates patient-team relationships for patients associated with other teams" do
      given_a_bulk_upload_team_exists
      and_a_poc_only_team_exists
      and_a_patient_is_associated_with_both_teams

      when_i_run_the_command_for_single_team

      then_all_the_immunisation_imports_are_deleted
      and_the_patient_is_not_deleted
      and_the_vaccination_record_is_deleted
      and_the_archive_reason_is_deleted
      and_the_patient_team_relationships_are_updated
    end

    it "handles the case when a non bulk upload team is in the same org" do
      given_a_bulk_upload_team_exists
      and_a_poc_only_team_exists_in_the_same_org_as_the_bulk_upload_team
      and_the_bulk_upload_team_has_immunisation_imports_with_vaccination_records

      when_i_run_the_command_for_single_team

      then_all_the_immunisation_imports_are_deleted
      and_all_the_vaccination_records_are_deleted
      and_all_the_archive_reasons_are_deleted
      and_all_the_patients_are_deleted
    end

    it "raises an error when team is not found" do
      expect { run_command_with_workgroup("nonexistent-team") }.to raise_error(
        ArgumentError,
        /Team not found/
      )
    end

    it "raises an error when team is not a bulk upload team" do
      given_a_poc_only_team_exists
      expect { run_command_with_workgroup(@poc_team.workgroup) }.to raise_error(
        ArgumentError,
        /not a bulk upload team/
      )
    end

    it "does not delete records that have been sent to the Imms API" do
      given_a_bulk_upload_team_exists
      and_the_bulk_upload_team_has_immunisation_imports_with_vaccination_records
      and_some_vaccination_records_have_been_sent_to_the_imms_api

      when_i_run_the_command_for_single_team

      then_the_immunisation_imports_of_the_synced_vaccination_records_are_not_deleted
      and_the_synced_vaccination_records_are_not_deleted
      and_the_archive_reasons_of_the_synced_vaccination_records_are_not_deleted
      and_the_patients_of_the_synced_vaccination_records_are_not_deleted

      and_the_other_immunisation_imports_are_deleted
      and_the_other_vaccination_records_are_deleted
      and_the_other_archive_reasons_are_deleted
      and_the_other_patients_are_deleted
    end
  end

  context "when resetting all bulk upload teams" do
    it "resets all bulk upload teams" do
      given_multiple_bulk_upload_teams_exist
      and_each_team_has_immunisation_imports

      when_i_run_the_command_for_all_teams

      then_all_the_immunisation_imports_are_deleted
      and_all_the_vaccination_records_are_deleted
      and_all_the_patients_are_deleted
    end

    it "does not affect poc_only teams" do
      given_a_poc_only_team_exists
      and_a_bulk_upload_team_exists
      and_the_poc_team_has_an_immunisation_import
      and_the_bulk_upload_team_has_immunisation_imports_with_vaccination_records

      when_i_run_the_command_for_all_teams

      then_the_poc_team_imports_are_not_deleted
      and_the_poc_team_vaccination_records_are_not_deleted
      and_the_poc_patients_are_not_deleted

      and_only_the_bulk_upload_team_imports_are_deleted
      and_only_the_bulk_upload_team_vaccination_records_are_deleted
      and_only_the_bulk_upload_team_patients_are_deleted
    end

    it "handles the case when no bulk upload teams exist" do
      given_a_poc_only_team_exists
      and_the_poc_team_has_an_immunisation_import

      when_i_run_the_command_for_all_teams

      then_the_output_indicates_no_teams_found
      and_no_immunisation_imports_are_deleted
      and_no_vaccination_records_are_deleted
      and_no_patients_are_deleted
    end
  end

  private

  def given_a_bulk_upload_team_exists
    @bulk_team =
      create(
        :team,
        :with_one_nurse,
        :upload_only,
        programmes: [Programme.hpv, Programme.flu],
        organisation: bulk_organisation,
        workgroup: "bulk-team"
      )
  end

  alias_method :and_a_bulk_upload_team_exists, :given_a_bulk_upload_team_exists

  def and_the_feature_flag_is_enabled
    Flipper.enable(:sync_national_reporting_to_imms_api)
  end

  def given_a_poc_only_team_exists
    @poc_team =
      create(
        :team,
        type: :poc_only,
        organisation: poc_organisation,
        workgroup: "poc-team"
      )
  end
  alias_method :and_a_poc_only_team_exists, :given_a_poc_only_team_exists

  def and_a_poc_only_team_exists_in_the_same_org_as_the_bulk_upload_team
    @poc_team =
      create(
        :team,
        type: :poc_only,
        organisation: bulk_organisation,
        workgroup: "poc-team"
      )
  end

  def and_i_upload_some_vaccination_records
    create(:school, team: @bulk_team, urn: 100_000)

    @user = @bulk_team.users.first
    sign_in @user

    visit "/immunisation-imports/new"
    attach_file(
      "immunisation_import[csv]",
      "spec/fixtures/immunisation_import_bulk/valid_mixed_flu_hpv.csv"
    )
    click_on "Continue"
    wait_for_import_to_complete(ImmunisationImport)
    expect(page).to have_content("StatusCompleted")
  end

  def and_the_bulk_upload_team_has_immunisation_imports_with_vaccination_records
    @import1 = create(:immunisation_import, team: @bulk_team)
    @import2 = create(:immunisation_import, team: @bulk_team)

    @vaccination_record1 =
      create(
        :vaccination_record,
        :sourced_from_bulk_upload,
        :with_archived_patient,
        immunisation_import: @import1,
        team: @bulk_team,
        performed_at: 1.day.ago
      )
    @vaccination_record2 =
      create(
        :vaccination_record,
        :sourced_from_bulk_upload,
        :with_archived_patient,
        immunisation_import: @import2,
        team: @bulk_team,
        performed_at: 2.days.ago
      )

    @patient1 = @vaccination_record1.patient
    @patient2 = @vaccination_record2.patient

    PatientTeamUpdater.call(patient_scope: Patient.all)
  end

  def and_a_patient_is_associated_with_both_teams
    @import = create(:immunisation_import, team: @bulk_team)
    @shared_patient = create(:patient)
    @bulk_upload_vaccination_record =
      create(
        :vaccination_record,
        :sourced_from_bulk_upload,
        immunisation_import: @import,
        team: @bulk_team,
        patient: @shared_patient,
        performed_at: 1.day.ago
      )

    @other_vaccination_record =
      create(
        :vaccination_record,
        team: @poc_team,
        patient: @shared_patient,
        performed_at: 2.days.ago
      )
  end

  def given_multiple_bulk_upload_teams_exist
    @bulk_team1 =
      create(
        :team,
        :upload_only,
        organisation: bulk_organisation,
        workgroup: "bulk-1"
      )
    @bulk_team2 =
      create(
        :team,
        :upload_only,
        organisation: bulk_organisation,
        workgroup: "bulk-2"
      )
  end

  def and_each_team_has_immunisation_imports
    @import1 = create(:immunisation_import, team: @bulk_team1)
    @import2 = create(:immunisation_import, team: @bulk_team2)

    @vaccination_record1 =
      create(
        :vaccination_record,
        :sourced_from_bulk_upload,
        immunisation_import: @import1,
        team: @bulk_team1,
        performed_at: 1.day.ago
      )
    @vaccination_record2 =
      create(
        :vaccination_record,
        :sourced_from_bulk_upload,
        immunisation_import: @import2,
        team: @bulk_team2,
        performed_at: 2.days.ago
      )

    @patient1 = @vaccination_record1.patient
    @patient2 = @vaccination_record2.patient
  end

  def and_the_poc_team_has_an_immunisation_import
    @poc_import = create(:immunisation_import, team: @poc_team)
    @poc_patient = create(:patient)
    @poc_vaccination_record =
      create(
        :vaccination_record,
        team: @poc_team,
        patient: @poc_patient,
        performed_at: 1.day.ago
      )

    @poc_import.vaccination_records << @poc_vaccination_record
    @poc_import.patients << @poc_patient
  end

  def and_some_vaccination_records_have_been_sent_to_the_imms_api
    @vaccination_record1.update(nhs_immunisations_api_synced_at: 1.hour.ago)
  end

  def when_i_run_the_command_for_single_team
    run_command_with_workgroup(@bulk_team.workgroup)
  end

  def when_i_run_the_command_for_all_teams
    run_command_without_workgroup
  end

  def run_command_with_workgroup(workgroup)
    @output =
      capture_output(input: "y") do
        Dry::CLI.new(MavisCLI).call(
          arguments: ["teams", "reset-bulk-upload", "--workgroup", workgroup]
        )
      end
  end

  def run_command_without_workgroup
    @output =
      capture_output(input: "y") do
        Dry::CLI.new(MavisCLI).call(arguments: %w[teams reset-bulk-upload])
      end
  end

  def then_an_error_is_displayed_in_output
    expect(@output).to include(
      "Error: This operation is not allowed while sync_national_reporting_to_imms_api is enabled."
    )
  end

  def then_all_the_immunisation_imports_are_deleted
    expect(ImmunisationImport.count).to be 0
  end

  def and_all_the_vaccination_records_are_deleted
    expect(VaccinationRecord.count).to be 0
  end

  def and_all_the_archive_reasons_are_deleted
    expect(ArchiveReason.count).to be 0
  end

  def and_all_the_patients_are_deleted
    expect(Patient.count).to be 0
  end

  def and_the_patient_is_not_deleted
    expect(Patient.where(id: @shared_patient.id)).to exist
  end

  def and_the_patient_team_relationships_are_updated
    expect(@shared_patient.patient_teams.pluck(:team_id)).to eq([@poc_team.id])
  end

  def and_the_vaccination_record_is_deleted
    expect(
      VaccinationRecord.where(id: [@bulk_upload_vaccination_record.id])
    ).to be_empty
  end

  def and_the_archive_reason_is_deleted
    expect(
      ArchiveReason.where(team: @bulk_team, patient: @shared_patient)
    ).to be_empty
  end

  def then_the_poc_team_imports_are_not_deleted
    expect(ImmunisationImport.where(id: @poc_import.id)).to exist
    expect(VaccinationRecord.where(id: @poc_vaccination_record.id)).to exist
  end

  def and_only_the_bulk_upload_team_imports_are_deleted
    bulk_imports = ImmunisationImport.where(team: @bulk_team)
    expect(bulk_imports).to be_empty
  end

  def and_the_poc_team_vaccination_records_are_not_deleted
    expect(VaccinationRecord.where(id: @poc_vaccination_record.id)).to exist
  end

  def and_only_the_bulk_upload_team_vaccination_records_are_deleted
    bulk_vaccination_records =
      VaccinationRecord.where(
        id: [@vaccination_record1.id, @vaccination_record2.id]
      )
    expect(bulk_vaccination_records).to be_empty
  end

  def and_only_the_bulk_upload_team_patients_are_deleted
    bulk_patients = Patient.where(id: [@patient1.id, @patient2.id])
    expect(bulk_patients).to be_empty
  end

  def and_the_poc_patients_are_not_deleted
    expect(Patient.where(id: @poc_patient.id)).to exist
  end

  def then_the_output_indicates_no_teams_found
    expect(@output).to include("No bulk upload teams found")
  end

  def and_no_immunisation_imports_are_deleted
    expect(ImmunisationImport.count).to be >= 1
  end

  def and_no_vaccination_records_are_deleted
    expect(VaccinationRecord.count).to be >= 1
  end

  def and_no_patients_are_deleted
    expect(Patient.count).to be >= 1
  end

  def then_the_immunisation_imports_of_the_synced_vaccination_records_are_not_deleted
    expect(ImmunisationImport.where(id: @import1.id)).to exist
  end

  def and_the_synced_vaccination_records_are_not_deleted
    expect(VaccinationRecord.where(id: @vaccination_record1.id)).to exist
  end

  def and_the_patients_of_the_synced_vaccination_records_are_not_deleted
    expect(Patient.where(id: @patient1.id)).to exist
  end

  def and_the_archive_reasons_of_the_synced_vaccination_records_are_not_deleted
    expect(ArchiveReason.where(team: @bulk_team, patient: @patient1)).to exist
  end

  def and_the_other_immunisation_imports_are_deleted
    expect(ImmunisationImport.where(id: @import2.id)).to be_empty
  end

  def and_the_other_vaccination_records_are_deleted
    expect(VaccinationRecord.where(id: @vaccination_record2.id)).to be_empty
  end

  def and_the_other_archive_reasons_are_deleted
    expect(
      ArchiveReason.where(team: @bulk_team, patient: @patient2)
    ).to be_empty
  end

  def and_the_other_patients_are_deleted
    expect(Patient.where(id: @patient2.id)).to be_empty
  end
end
