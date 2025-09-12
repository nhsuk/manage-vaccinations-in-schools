# frozen_string_literal: true

describe CommitPatientChangesetsJob do
  let(:team) { create(:team) }
  let(:import) { create(:cohort_import, team:) }

  describe "#import_patients_and_parents" do
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
