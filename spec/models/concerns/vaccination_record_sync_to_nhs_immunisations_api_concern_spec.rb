# frozen_string_literal: true

describe VaccinationRecordSyncToNHSImmunisationsAPIConcern do
  let(:vaccination_record) do
    build(:vaccination_record, outcome:, programme:, session:)
  end
  let(:outcome) { "administered" }
  let(:programme) { create(:programme, type: "flu") }
  let(:session) { create(:session, programmes: [programme]) }

  describe "#sync_to_nhs_immunisations_api" do
    before { Flipper.enable(:enqueue_sync_vaccination_records_to_nhs) }

    it "enqueues the job if the vaccination record is elligible to sync" do
      expect {
        vaccination_record.sync_to_nhs_immunisations_api
      }.to have_enqueued_job(SyncVaccinationRecordToNHSJob)
    end

    it "sets nhs_immunistaions_api_sync_pending_at" do
      freeze_time do
        expect { vaccination_record.sync_to_nhs_immunisations_api }.to change(
          vaccination_record,
          :nhs_immunisations_api_sync_pending_at
        ).from(nil).to(Time.current)
      end
    end

    context "when the vaccination record isn't syncable" do
      before do
        allow(vaccination_record).to receive(
          :syncable_to_nhs_immunisations_api?
        ).and_return(false)
      end

      it "does not enqueue the job" do
        expect {
          vaccination_record.sync_to_nhs_immunisations_api
        }.not_to have_enqueued_job(SyncVaccinationRecordToNHSJob)
      end

      it "does not set nhs_immunistaions_api_sync_pending_at" do
        expect {
          vaccination_record.sync_to_nhs_immunisations_api
        }.not_to change(
          vaccination_record,
          :nhs_immunisations_api_sync_pending_at
        )
      end
    end

    context "when the feature flag is disabled" do
      before { Flipper.disable(:enqueue_sync_vaccination_records_to_nhs) }

      let(:vaccination_record) { create(:vaccination_record) }

      it "does not enqueue the job" do
        expect {
          vaccination_record.sync_to_nhs_immunisations_api
        }.not_to have_enqueued_job(SyncVaccinationRecordToNHSJob)
      end

      it "does not set nhs_immunistaions_api_sync_pending_at" do
        expect {
          vaccination_record.sync_to_nhs_immunisations_api
        }.not_to change(
          vaccination_record,
          :nhs_immunisations_api_sync_pending_at
        )
      end
    end
  end

  describe "syncable_to_nhs_immunisations_api scope" do
    subject { VaccinationRecord.syncable_to_nhs_immunisations_api }

    let!(:vaccination_record) do
      create(:vaccination_record, programme:, session:)
    end
    let!(:vaccination_record_outside_of_session) do
      create(:vaccination_record, programme:)
    end

    it { should include(vaccination_record) }
    it { should_not include(vaccination_record_outside_of_session) }
  end

  describe "#syncable_to_nhs_immunisations_api?" do
    subject { vaccination_record.syncable_to_nhs_immunisations_api? }

    context "when the vaccination record is eligible to sync" do
      it { should be true }
    end

    context "a discarded vaccination record" do
      before { vaccination_record.discard! }

      it { should be true }
    end

    context "a vaccination record not recorded in Mavis" do
      let(:session) { nil }

      it { should be false }
    end

    context "a patient without an nhs number" do
      let(:patient) do
        create(:patient, nhs_number: nil, school: session.location)
      end
      let(:vaccination_record) do
        create(:vaccination_record, outcome:, programme:, session:, patient:)
      end

      it { should be true }
    end

    VaccinationRecord.defined_enums["outcome"].each_key do |outcome|
      next if outcome == "administered"

      context "when the vaccination record outcome is #{outcome}" do
        let(:outcome) { outcome }

        it { should be true }
      end
    end

    Programme.defined_enums["type"].each_key do |programme_type|
      next if programme_type.in? %w[flu hpv]

      context "when the programme type is #{programme_type}" do
        let(:programme) { create(:programme, type: programme_type) }

        it { should be true }
      end
    end
  end
end
