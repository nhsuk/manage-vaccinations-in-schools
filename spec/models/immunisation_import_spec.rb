# frozen_string_literal: true

# == Schema Information
#
# Table name: immunisation_imports
#
#  id                           :bigint           not null, primary key
#  changed_record_count         :integer
#  csv_data                     :text
#  csv_filename                 :text             not null
#  csv_removed_at               :datetime
#  exact_duplicate_record_count :integer
#  new_record_count             :integer
#  processed_at                 :datetime
#  rows_count                   :integer
#  serialized_errors            :jsonb
#  status                       :integer          default("pending_import"), not null
#  created_at                   :datetime         not null
#  updated_at                   :datetime         not null
#  team_id                      :bigint           not null
#  uploaded_by_user_id          :bigint           not null
#
# Indexes
#
#  index_immunisation_imports_on_team_id              (team_id)
#  index_immunisation_imports_on_uploaded_by_user_id  (uploaded_by_user_id)
#
# Foreign Keys
#
#  fk_rails_...  (team_id => teams.id)
#  fk_rails_...  (uploaded_by_user_id => users.id)
#

describe ImmunisationImport do
  subject(:immunisation_import) do
    create(:immunisation_import, team:, csv:, uploaded_by:)
  end

  before do
    create(:school, urn: "110158", systm_one_code: "TT110158")
    create(:school, urn: "120026")
    create(:school, urn: "144012")
  end

  let(:programmes) { [create(:programme, :flu_all_vaccines)] }
  let(:team) do
    create(:team, :with_generic_clinic, ods_code: "R1L", programmes:)
  end

  let(:file) { "valid_flu.csv" }
  let(:csv) { fixture_file_upload("spec/fixtures/immunisation_import/#{file}") }
  let(:uploaded_by) { create(:user, team:) }

  it_behaves_like "a CSVImportable model"

  describe "#load_data!" do
    before { immunisation_import.load_data! }

    context "with malformed CSV" do
      let(:file) { "malformed.csv" }

      it "is invalid" do
        expect(immunisation_import).to be_invalid
        expect(immunisation_import.errors[:csv]).to include(/correct format/)
      end
    end

    context "with empty CSV" do
      let(:file) { "empty.csv" }

      it "is invalid" do
        expect(immunisation_import).to be_invalid
        expect(immunisation_import.errors[:csv]).to include(/one record/)
      end
    end
  end

  describe "#parse_rows!" do
    before { immunisation_import.parse_rows! }

    around { |example| travel_to(Date.new(2025, 8, 1)) { example.run } }

    context "with valid Flu rows" do
      let(:programmes) { [create(:programme, :flu_all_vaccines)] }
      let(:file) { "valid_flu.csv" }

      it "populates the rows" do
        expect(immunisation_import).to be_valid
        expect(immunisation_import.rows).not_to be_empty
      end
    end

    context "with valid HPV rows" do
      let(:programmes) { [create(:programme, :hpv_all_vaccines)] }
      let(:file) { "valid_hpv.csv" }

      it "populates the rows" do
        expect(immunisation_import).to be_valid
        expect(immunisation_import.rows).not_to be_empty
      end
    end

    context "with a SystmOne file" do
      let(:programmes) do
        [
          create(:programme, :hpv_all_vaccines),
          create(:programme, :menacwy),
          create(:programme, :flu)
        ]
      end
      let(:file) { "systm_one.csv" }

      it "populates the rows" do
        expect(immunisation_import).to be_valid
        expect(immunisation_import.rows).not_to be_empty
      end
    end

    context "with invalid rows" do
      let(:file) { "invalid_rows.csv" }

      it "is invalid" do
        expect(immunisation_import).to be_invalid
        expect(immunisation_import.errors).not_to include(:row_1) # Header row
        expect(immunisation_import.errors).to include(:row_2, :row_3)
      end
    end
  end

  describe "#process!" do
    subject(:process!) { immunisation_import.process! }

    around { |example| travel_to(Date.new(2025, 8, 1)) { example.run } }

    context "with valid Flu rows" do
      let(:programmes) { [create(:programme, :flu_all_vaccines)] }
      let(:file) { "valid_flu.csv" }

      it "creates locations, patients, and vaccination records" do
        # stree-ignore
        expect { process! }
          .to change(immunisation_import, :processed_at).from(nil)
          .and change(immunisation_import.vaccination_records, :count).by(11)
          .and change(immunisation_import.patients, :count).by(11)
          .and change(immunisation_import.batches, :count).by(4)
          .and not_change(immunisation_import.patient_sessions, :count)

        # Second import should not duplicate the vaccination records if they're
        # identical.

        # stree-ignore
        expect { immunisation_import.process! }
          .to not_change(immunisation_import, :processed_at)
          .and not_change(VaccinationRecord, :count)
          .and not_change(Patient, :count)
          .and not_change(PatientSession, :count)
          .and not_change(Batch, :count)
      end

      it "stores statistics on the import" do
        # stree-ignore
        expect { process! }
          .to change(immunisation_import, :exact_duplicate_record_count).to(0)
          .and change(immunisation_import, :new_record_count).to(11)
      end

      it "ignores and counts duplicate records" do
        create(:immunisation_import, csv:, team:, uploaded_by:).process!
        csv.rewind

        process!
        expect(immunisation_import.exact_duplicate_record_count).to eq(11)
      end

      it "enqueues jobs to look up missing NHS numbers" do
        expect { process! }.to have_enqueued_job(
          PatientNHSNumberLookupJob
        ).once.on_queue(:imports)
      end

      it "enqueues jobs to update from PDS" do
        expect { process! }.to have_enqueued_job(PatientUpdateFromPDSJob)
          .exactly(10)
          .times
          .on_queue(:imports)
      end
    end

    context "with valid HPV rows" do
      let(:programmes) { [create(:programme, :hpv_all_vaccines)] }
      let(:file) { "valid_hpv.csv" }

      it "creates locations, patients, and vaccination records" do
        # stree-ignore
        expect { process! }
          .to change(immunisation_import, :processed_at).from(nil)
          .and change(immunisation_import.vaccination_records, :count).by(11)
          .and change(immunisation_import.patients, :count).by(10)
          .and change(immunisation_import.batches, :count).by(8)
          .and not_change(immunisation_import.patient_sessions, :count)

        # Second import should not duplicate the vaccination records if they're
        # identical.

        # stree-ignore
        expect { immunisation_import.process! }
          .to not_change(immunisation_import, :processed_at)
          .and not_change(VaccinationRecord, :count)
          .and not_change(Patient, :count)
          .and not_change(PatientSession, :count)
          .and not_change(Batch, :count)
      end

      it "stores statistics on the import" do
        # stree-ignore
        expect { process! }
          .to change(immunisation_import, :exact_duplicate_record_count).to(0)
          .and change(immunisation_import, :new_record_count).to(11)
      end

      it "ignores and counts duplicate records" do
        create(:immunisation_import, csv:, team:, uploaded_by:).process!
        csv.rewind

        process!
        expect(immunisation_import.exact_duplicate_record_count).to eq(11)
      end

      it "enqueues jobs to look up missing NHS numbers" do
        expect { process! }.to have_enqueued_job(
          PatientNHSNumberLookupJob
        ).once.on_queue(:imports)
      end

      it "enqueues jobs to update from PDS" do
        expect { process! }.to have_enqueued_job(PatientUpdateFromPDSJob)
          .exactly(9)
          .times
          .on_queue(:imports)
      end
    end

    context "with a SystmOne file format" do
      let(:programmes) do
        [
          create(:programme, :hpv_all_vaccines),
          create(:programme, :menacwy),
          create(:programme, :flu)
        ]
      end
      let(:file) { "systm_one.csv" }

      it "creates locations, patients, and vaccination records" do
        # stree-ignore
        expect { process! }
          .to change(immunisation_import, :processed_at).from(nil)
          .and change(immunisation_import.vaccination_records, :count).by(4)
          .and change(immunisation_import.patients, :count).by(4)
          .and change(immunisation_import.batches, :count).by(1)
          .and not_change(immunisation_import.patient_sessions, :count)

        # Second import should not duplicate the vaccination records if they're
        # identical.

        # stree-ignore
        expect { immunisation_import.process! }
          .to not_change(immunisation_import, :processed_at)
          .and not_change(VaccinationRecord, :count)
          .and not_change(Patient, :count)
          .and not_change(PatientSession, :count)
          .and not_change(Batch, :count)
      end
    end

    context "with an existing patient matching the name" do
      let(:programmes) { [create(:programme, :flu_all_vaccines)] }
      let(:file) { "valid_flu.csv" }

      let!(:patient) do
        create(
          :patient,
          given_name: "Chyna",
          family_name: "Pickle",
          date_of_birth: Date.new(2012, 9, 12),
          nhs_number: nil
        )
      end

      it "doesn't create an additional patient" do
        expect { process! }.to change(Patient, :count).by(10)
      end

      it "doesn't update the NHS number on the existing patient" do
        expect { process! }.not_to change(patient, :nhs_number).from(nil)
      end
    end

    context "with an existing patient matching the name but with a different case" do
      let(:programmes) { [create(:programme, :flu_all_vaccines)] }
      let(:file) { "valid_flu.csv" }

      before do
        create(
          :patient,
          given_name: "chyna",
          family_name: "PICKLE",
          date_of_birth: Date.new(2012, 9, 12),
          nhs_number: nil
        )
      end

      it "doesn't create an additional patient" do
        expect { process! }.to change(Patient, :count).by(10)
      end
    end

    context "with a patient record that has different attributes" do
      let(:programmes) { [create(:programme, :hpv_all_vaccines)] }
      let(:file) { "valid_hpv_with_changes.csv" }
      let!(:existing_patient) do
        create(
          :patient,
          nhs_number: "7420180008",
          given_name: "Chyna",
          family_name: "Pickle",
          date_of_birth: Date.new(2011, 9, 12),
          gender_code: "not_specified",
          address_postcode: "LE3 2DA"
        )
      end

      it "ignores changes in the patient record" do
        expect { process! }.not_to change(Patient, :count)
        expect(existing_patient.reload.pending_changes).to be_empty
      end
    end
  end

  describe "#postprocess_row!" do
    subject(:immunisation_import) do
      create(
        :immunisation_import,
        team:,
        vaccination_records: [vaccination_record]
      )
    end

    before { Flipper.enable :enqueue_sync_vaccination_records_to_nhs }

    let(:session) { create(:session, programmes:) }
    let(:vaccination_record) do
      create(:vaccination_record, programme: programmes.first, session:)
    end

    it "syncs the flu vaccination record to the NHS Immunisations API" do
      expect {
        immunisation_import.send(:postprocess_rows!)
      }.to have_enqueued_job(SyncVaccinationRecordToNHSJob)
        .with(vaccination_record)
        .once
        .on_queue(:immunisation_api)
    end
  end
end
