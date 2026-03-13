# frozen_string_literal: true

describe CommitImportJob do
  subject(:perform_job) do
    described_class.new.perform(import.to_global_id.to_s)
  end

  let(:programmes) { [Programme.hpv] }
  let(:team) { create(:team, :with_generic_clinic, programmes:) }
  let(:location) { create(:school, team:) }
  let(:session) { create(:session, location:, programmes:, team:) }

  let(:file) { "valid.csv" }
  let(:csv) { fixture_file_upload("class_import/#{file}") }
  let(:import) { create(:class_import, csv:, session:, team:) }

  before do
    import.load_data!
    import.parse_rows!
    import.rows.each_with_index.map do |row, row_number|
      PatientChangeset.from_import_row(row:, import:, row_number:)
    end
    import.save!
  end

  it_behaves_like "a method that updates team cached counts"

  describe "#perform" do
    context "PDS search is disabled" do
      before { Flipper.disable(:import_search_pds) }
      after { Flipper.enable(:import_search_pds) }

      it "processes the import normally" do
        expect { perform_job }.to change(Patient, :count).by(4)
        expect(import.reload.status).to eq("processed")
      end
    end

    context "PDS search is enabled" do
      before { Flipper.enable(:import_search_pds) }
      after { Flipper.disable(:import_search_pds) }

      context "and import is below match rate threshold" do
        before do
          create_list(:patient_changeset, 6, :with_pds_match, import:)
          create_list(:patient_changeset, 4, import:)
          import.validate_pds_match_rate!
        end

        it "marks the import as low_pds_match_rate and stops processing" do
          expect(import).to receive(:validate_pds_match_rate!).and_call_original
          expect(import).not_to receive(:postprocess_rows!)
          allow(ClassImport).to receive(:find).with(import.id.to_s).and_return(
            import
          )

          perform_job
          expect(import.reload.status).to eq("low_pds_match_rate")
        end
      end

      context "and import is above match rate threshold" do
        before do
          create_list(:patient_changeset, 7, :with_pds_match, import:)
          create_list(:patient_changeset, 3, import:)
          import.validate_pds_match_rate!
        end

        it "continues processing normally" do
          expect { perform_job }.to change(Patient, :count).by(14) # 4 from CSV + 10 from setup
          expect(import.reload.status).to eq("processed")
        end
      end
    end
  end

  describe "#import_patients_and_parents" do
    context "when patients have NHS number changes" do
      subject(:import_patients_and_parents) do
        job = described_class.new
        job.send(:import_patients_and_parents, changesets, import)
      end

      let!(:first_patient) { create(:patient) }
      let!(:second_patient) { create(:patient) }
      let!(:third_patient) { create(:patient, nhs_number: nil) }
      let(:patients) { [first_patient, second_patient, third_patient] }

      let(:changesets) do
        patients.map do |patient|
          instance_double(
            PatientChangeset,
            patient:,
            parents: [],
            parent_relationships: []
          )
        end
      end

      before do
        allow(Patient).to receive(:import)
        allow(PatientChangeset).to receive(:import)
        allow(Parent).to receive(:import)
        allow(ParentRelationship).to receive(:import)

        changesets.each do |changeset|
          allow(changeset).to receive(:assign_patient_id)
        end
      end

      context "when patients have NHS number changes" do
        before do
          allow(first_patient).to receive(
            :nhs_number_previously_changed?
          ).and_return(true)
          allow(second_patient).to receive(
            :nhs_number_previously_changed?
          ).and_return(true)
          allow(third_patient).to receive(
            :nhs_number_previously_changed?
          ).and_return(false)
        end

        it "enqueues SearchVaccinationRecordsInNHSJob for patients with NHS number changes" do
          import_patients_and_parents

          expect(SearchVaccinationRecordsInNHSJob).to have_enqueued_sidekiq_job(
            first_patient.id
          )
          expect(SearchVaccinationRecordsInNHSJob).to have_enqueued_sidekiq_job(
            second_patient.id
          )
          expect(
            SearchVaccinationRecordsInNHSJob
          ).not_to have_enqueued_sidekiq_job(third_patient.id)
        end
      end

      context "when no patients have NHS number changes" do
        before do
          allow(first_patient).to receive(
            :nhs_number_previously_changed?
          ).and_return(false)
          allow(second_patient).to receive(
            :nhs_number_previously_changed?
          ).and_return(false)
          allow(third_patient).to receive(
            :nhs_number_previously_changed?
          ).and_return(false)
        end

        it "does not enqueue SearchVaccinationRecordsInNHSJob" do
          expect { import_patients_and_parents }.not_to enqueue_sidekiq_job(
            SearchVaccinationRecordsInNHSJob
          )
        end
      end
    end
  end
end
