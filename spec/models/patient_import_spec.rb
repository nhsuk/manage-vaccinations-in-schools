# frozen_string_literal: true

describe PatientImport do
  let(:team) { create(:team) }
  let(:cohort_import) { create(:cohort_import, team:) }

  describe "#bulk_import" do
    let!(:first_patient) { create(:patient) }
    let!(:second_patient) { create(:patient) }
    let!(:third_patient) { create(:patient, nhs_number: nil) }

    before do
      cohort_import.instance_variable_set(
        :@patients_batch,
        Set.new([first_patient, second_patient, third_patient])
      )
      cohort_import.instance_variable_set(:@parents_batch, Set.new)
      cohort_import.instance_variable_set(:@relationships_batch, Set.new)
      cohort_import.instance_variable_set(:@school_moves_to_confirm, Set.new)
      cohort_import.instance_variable_set(:@school_moves_to_save, Set.new)
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
        cohort_import.send(:bulk_import, rows: :all)

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
        expect {
          cohort_import.send(:bulk_import, rows: :all)
        }.not_to enqueue_sidekiq_job(SearchVaccinationRecordsInNHSJob)
      end
    end
  end
end
