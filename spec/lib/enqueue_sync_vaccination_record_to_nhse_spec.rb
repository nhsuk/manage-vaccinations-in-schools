# frozen_string_literal: true

describe EnqueueSyncVaccinationRecordToNHSE do
  context "when the feature flag is disabled" do
    before { Flipper.disable(:sync_vaccination_records_to_nhse_on_create) }

    let(:vaccination_record) { create(:vaccination_record) }

    it "does not enqueue the job" do
      expect {
        described_class.call(vaccination_record)
      }.not_to have_enqueued_job(SyncVaccinationRecordToNHSEJob)
    end
  end

  context "when the feature flag is enabled" do
    before { Flipper.enable(:sync_vaccination_records_to_nhse_on_create) }

    let(:vaccination_record) do
      create(:vaccination_record, outcome:, programme:)
    end
    let(:outcome) { "administered" }
    let(:programme) { create(:programme, type: "flu") }

    context "when the vaccination record is eligible for syncing" do
      it "enqueues the job" do
        expect {
          described_class.call(vaccination_record)
        }.to have_enqueued_job(SyncVaccinationRecordToNHSEJob)
      end
    end

    VaccinationRecord.defined_enums["outcome"].each_key do |outcome|
      next if outcome == "administered"

      context "when the vaccination record outcome is #{outcome}" do
        let(:outcome) { outcome }

        it "does not enqueue the job" do
          expect {
            described_class.call(vaccination_record)
          }.not_to have_enqueued_job(SyncVaccinationRecordToNHSEJob)
        end
      end
    end

    Programme.defined_enums["type"].each_key do |programme_type|
      next if programme_type.in? %w[flu hpv]

      context "when the programme type is #{programme_type}" do
        let(:programme) { create(:programme, type: programme_type) }

        it "does not enqueue the job" do
          expect {
            described_class.call(vaccination_record)
          }.not_to have_enqueued_job(SyncVaccinationRecordToNHSEJob)
        end
      end
    end
  end
end
