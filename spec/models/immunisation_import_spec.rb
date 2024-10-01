# frozen_string_literal: true

# == Schema Information
#
# Table name: immunisation_imports
#
#  id                            :bigint           not null, primary key
#  changed_record_count          :integer
#  csv_data                      :text
#  csv_filename                  :text             not null
#  csv_removed_at                :datetime
#  exact_duplicate_record_count  :integer
#  new_record_count              :integer
#  not_administered_record_count :integer
#  processed_at                  :datetime
#  recorded_at                   :datetime
#  serialized_errors             :jsonb
#  status                        :integer          default("pending_import"), not null
#  created_at                    :datetime         not null
#  updated_at                    :datetime         not null
#  programme_id                  :bigint           not null
#  team_id                       :bigint           not null
#  uploaded_by_user_id           :bigint           not null
#
# Indexes
#
#  index_immunisation_imports_on_programme_id         (programme_id)
#  index_immunisation_imports_on_team_id              (team_id)
#  index_immunisation_imports_on_uploaded_by_user_id  (uploaded_by_user_id)
#
# Foreign Keys
#
#  fk_rails_...  (programme_id => programmes.id)
#  fk_rails_...  (team_id => teams.id)
#  fk_rails_...  (uploaded_by_user_id => users.id)
#

describe ImmunisationImport do
  subject(:immunisation_import) do
    create(:immunisation_import, team:, programme:, csv:, uploaded_by:)
  end

  before do
    create(:location, :school, urn: "110158")
    create(:location, :school, urn: "120026")
    create(:location, :school, urn: "144012")
  end

  let(:programme) { create(:programme, :flu_all_vaccines) }
  let(:team) { create(:team, ods_code: "R1L", programmes: [programme]) }

  let(:file) { "valid_flu.csv" }
  let(:csv) { fixture_file_upload("spec/fixtures/immunisation_import/#{file}") }
  let(:uploaded_by) { create(:user, teams: [team]) }

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

    context "with missing headers" do
      let(:file) { "missing_headers.csv" }

      it "is invalid" do
        expect(immunisation_import).to be_invalid
        expect(immunisation_import.errors[:csv]).to include(/missing/)
      end
    end
  end

  describe "#parse_rows!" do
    before { immunisation_import.parse_rows! }

    context "with valid Flu rows" do
      let(:programme) { create(:programme, :flu_all_vaccines) }
      let(:file) { "valid_flu.csv" }

      it "populates the rows" do
        expect(immunisation_import).to be_valid
        expect(immunisation_import.rows).not_to be_empty
      end
    end

    context "with valid HPV rows" do
      let(:programme) { create(:programme, :hpv_all_vaccines) }
      let(:file) { "valid_hpv.csv" }

      it "populates the rows" do
        expect(immunisation_import).to be_valid
        expect(immunisation_import.rows).not_to be_empty
      end
    end

    context "with invalid rows" do
      let(:file) { "invalid_rows.csv" }

      it "is invalid" do
        expect(immunisation_import).to be_invalid
        expect(immunisation_import.errors).to include(:row_1)
      end
    end
  end

  describe "#process!" do
    subject(:process!) { immunisation_import.process! }

    context "with valid Flu rows" do
      let(:programme) { create(:programme, :flu_all_vaccines) }
      let(:file) { "valid_flu.csv" }

      it "creates locations, patients, and vaccination records" do
        # stree-ignore
        expect { process! }
          .to change(immunisation_import, :processed_at).from(nil)
          .and change(immunisation_import.vaccination_records, :count).by(7)
          .and change(immunisation_import.locations, :count).by(1)
          .and change(immunisation_import.patients, :count).by(7)
          .and change(immunisation_import.sessions, :count).by(1)
          .and change(immunisation_import.patient_sessions, :count).by(7)
          .and change(immunisation_import.batches, :count).by(4)

        # Second import should not duplicate the vaccination records if they're
        # identical.

        # stree-ignore
        expect { immunisation_import.process! }
          .to not_change(immunisation_import, :processed_at)
          .and not_change(VaccinationRecord, :count)
          .and not_change(Location, :count)
          .and not_change(Patient, :count)
          .and not_change(Session, :count)
          .and not_change(PatientSession, :count)
          .and not_change(Batch, :count)
      end

      it "stores statistics on the import" do
        # stree-ignore
        expect { process! }
          .to change(immunisation_import, :exact_duplicate_record_count).to(0)
          .and change(immunisation_import, :new_record_count).to(7)
          .and change(immunisation_import, :not_administered_record_count).to(4)
      end

      it "ignores and counts duplicate records" do
        build(:immunisation_import, programme:, csv:, uploaded_by:).record!
        csv.rewind

        process!
        expect(immunisation_import.exact_duplicate_record_count).to eq(7)
      end
    end

    context "with valid HPV rows" do
      let(:programme) { create(:programme, :hpv_all_vaccines) }
      let(:file) { "valid_hpv.csv" }

      it "creates locations, patients, and vaccination records" do
        # stree-ignore
        expect { process! }
          .to change(immunisation_import, :processed_at).from(nil)
          .and change(immunisation_import.vaccination_records, :count).by(7)
          .and change(immunisation_import.locations, :count).by(1)
          .and change(immunisation_import.patients, :count).by(7)
          .and change(immunisation_import.sessions, :count).by(2)
          .and change(immunisation_import.patient_sessions, :count).by(7)
          .and change(immunisation_import.batches, :count).by(5)

        # Second import should not duplicate the vaccination records if they're
        # identical.

        # stree-ignore
        expect { immunisation_import.process! }
          .to not_change(immunisation_import, :processed_at)
          .and not_change(VaccinationRecord, :count)
          .and not_change(Location, :count)
          .and not_change(Patient, :count)
          .and not_change(Session, :count)
          .and not_change(PatientSession, :count)
          .and not_change(Batch, :count)
      end

      it "stores statistics on the import" do
        # stree-ignore
        expect { process! }
          .to change(immunisation_import, :exact_duplicate_record_count).to(0)
          .and change(immunisation_import, :new_record_count).to(7)
          .and change(immunisation_import, :not_administered_record_count).to(0)
      end

      it "ignores and counts duplicate records" do
        build(:immunisation_import, programme:, csv:, uploaded_by:).record!
        csv.rewind

        process!
        expect(immunisation_import.exact_duplicate_record_count).to eq(7)
      end

      it "creates a new session for each date" do
        process!

        expect(immunisation_import.sessions.count).to eq(2)

        session = immunisation_import.sessions.first
        expect(session.dates.map(&:value)).to contain_exactly(
          Date.new(2024, 5, 14)
        )
      end
    end

    context "with an existing patient matching the name" do
      let(:programme) { create(:programme, :flu_all_vaccines) }
      let(:file) { "valid_flu.csv" }

      let!(:patient) do
        create(
          :patient,
          first_name: "Chyna",
          last_name: "Pickle",
          date_of_birth: Date.new(2012, 9, 12),
          nhs_number: nil
        )
      end

      it "doesn't create an additional patient" do
        expect { process! }.to change(Patient, :count).by(6)
      end

      it "doesn't update the NHS number on the existing patient" do
        expect { process! }.not_to change(patient, :nhs_number).from(nil)
      end
    end

    context "with a patient record that has different attributes" do
      let(:programme) { create(:programme, :hpv_all_vaccines) }
      let(:file) { "valid_hpv_with_changes.csv" }
      let!(:existing_patient) do
        create(
          :patient,
          nhs_number: "7420180008",
          first_name: "Chyna",
          last_name: "Pickle",
          date_of_birth: Date.new(2011, 9, 12),
          gender_code: "not_specified",
          address_postcode: "LE3 2DA"
        )
      end

      it "identifies potential changes in the patient record" do
        expect { process! }.not_to change(Patient, :count)

        expect(existing_patient.reload.pending_changes).to eq(
          "address_postcode" => "LE3 2DB",
          "cohort_id" => team.cohorts.first.id,
          "date_of_birth" => "2011-09-13",
          "gender_code" => "female",
          "school_id" => Location.find_by(urn: "110158").id
        )
      end
    end
  end

  describe "#record!" do
    subject(:record!) { immunisation_import.record! }

    context "with valid Flu rows" do
      let(:programme) { create(:programme, :flu_all_vaccines) }
      let(:file) { "valid_flu.csv" }

      it "records the patients" do
        expect { record! }.to change(Patient.recorded, :count).from(0).to(7)
      end

      it "records the vaccination records" do
        expect { record! }.to change(VaccinationRecord.recorded, :count).from(
          0
        ).to(7)
      end

      it "activates the patient sessions" do
        expect { record! }.to change(PatientSession.active, :count).from(0).to(
          7
        )
      end
    end

    context "with valid HPV rows" do
      let(:programme) { create(:programme, :hpv_all_vaccines) }
      let(:file) { "valid_hpv.csv" }

      it "records the patients" do
        expect { record! }.to change(Patient.recorded, :count).from(0).to(7)
      end

      it "records the vaccination records" do
        expect { record! }.to change(VaccinationRecord.recorded, :count).from(
          0
        ).to(7)
      end

      it "activates the patient sessions" do
        expect { record! }.to change(PatientSession.active, :count).from(0).to(
          7
        )
      end
    end
  end
end
