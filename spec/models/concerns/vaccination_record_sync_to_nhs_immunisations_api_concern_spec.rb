# frozen_string_literal: true

describe VaccinationRecordSyncToNHSImmunisationsAPIConcern do
  let(:vaccination_record) do
    build(:vaccination_record, outcome:, programme:, session:)
  end
  let(:outcome) { "administered" }
  let(:programme) { create(:programme, type: "flu") }
  let(:session) { create(:session, programmes: [programme]) }

  describe "#sync_to_nhs_immunisations_api" do
    before { Flipper.enable(:imms_api_sync_job) }

    it "enqueues the job if the vaccination record is eligible to sync" do
      expect {
        vaccination_record.sync_to_nhs_immunisations_api
      }.to enqueue_sidekiq_job(SyncVaccinationRecordToNHSJob)
    end

    it "sets nhs_immunisations_api_sync_pending_at" do
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
        }.not_to enqueue_sidekiq_job(SyncVaccinationRecordToNHSJob)
      end

      it "does not set nhs_immunisations_api_sync_pending_at" do
        expect {
          vaccination_record.sync_to_nhs_immunisations_api
        }.not_to change(
          vaccination_record,
          :nhs_immunisations_api_sync_pending_at
        )
      end
    end

    context "when the feature flag is disabled" do
      before { Flipper.disable(:imms_api_sync_job) }

      let(:vaccination_record) { create(:vaccination_record) }

      it "does not enqueue the job" do
        expect {
          vaccination_record.sync_to_nhs_immunisations_api
        }.not_to enqueue_sidekiq_job(SyncVaccinationRecordToNHSJob)
      end

      it "does not set nhs_immunisations_api_sync_pending_at" do
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

  describe "#sync_status" do
    subject(:sync_status) { vaccination_record.sync_status }

    context "when patient has no NHS number" do
      let(:patient) do
        create(:patient, nhs_number: nil, school: session.location)
      end

      let(:vaccination_record) do
        create(:vaccination_record, outcome:, programme:, session:, patient:)
      end

      context "record needs to be synced" do
        it "returns :cannot_sync" do
          expect(sync_status).to eq(:cannot_sync)
        end
      end

      context "record was never going to be synced anyway" do
        before do
          allow(vaccination_record).to receive(:administered?).and_return(false)
        end

        it "returns :not_synced" do
          expect(sync_status).to eq(:not_synced)
        end
      end

      context "NHS number has been removed from patient after record was synced" do
        context "record is yet to be queued for deletion from API" do
          before do
            vaccination_record.update!(
              nhs_immunisations_api_sync_pending_at: 3.days.ago,
              nhs_immunisations_api_synced_at: 2.days.ago
            )
          end

          it "returns :cannot_sync" do
            expect(sync_status).to eq(:cannot_sync)
          end
        end

        context "record is pending deletion from API" do
          before do
            vaccination_record.update!(
              nhs_immunisations_api_sync_pending_at: 1.hour.ago,
              nhs_immunisations_api_synced_at: 2.days.ago
            )
          end

          it "returns :cannot_sync" do
            expect(sync_status).to eq(:cannot_sync)
          end
        end

        context "record is successfully deleted from API" do
          before do
            vaccination_record.update!(
              nhs_immunisations_api_sync_pending_at: 1.hour.ago,
              nhs_immunisations_api_synced_at: 1.minute.ago
            )
          end

          it "returns :cannot_sync" do
            expect(sync_status).to eq(:cannot_sync)
          end
        end
      end
    end

    context "when record has been synced successfully" do
      before do
        vaccination_record.update!(
          nhs_immunisations_api_sync_pending_at: 2.hours.ago,
          nhs_immunisations_api_synced_at: 1.hour.ago
        )
      end

      it "returns :synced" do
        expect(sync_status).to eq(:synced)
      end
    end

    context "when sync has been pending for less than 24 hours" do
      before do
        vaccination_record.update!(
          nhs_immunisations_api_sync_pending_at: 23.hours.ago,
          nhs_immunisations_api_synced_at: nil
        )
      end

      it "returns :pending" do
        expect(sync_status).to eq(:pending)
      end
    end

    context "when sync has been pending for more than 24 hours" do
      before do
        vaccination_record.update!(
          nhs_immunisations_api_sync_pending_at: 25.hours.ago,
          nhs_immunisations_api_synced_at: nil
        )
      end

      it "returns :failed" do
        expect(sync_status).to eq(:failed)
      end
    end

    context "when sync has been pending for more than 24 hours, and has been synced before" do
      before do
        vaccination_record.update!(
          nhs_immunisations_api_sync_pending_at: 25.hours.ago,
          nhs_immunisations_api_synced_at: 2.days.ago
        )
      end

      it "returns :failed" do
        expect(sync_status).to eq(:failed)
      end
    end

    context "when record was not administered" do
      before do
        vaccination_record.update!(
          nhs_immunisations_api_sync_pending_at: nil,
          nhs_immunisations_api_synced_at: nil
        )

        allow(vaccination_record).to receive(:administered?).and_return(false)
      end

      it "returns :not_synced" do
        expect(sync_status).to eq(:not_synced)
      end
    end

    context "when record was marked as already vaccinated" do
      let(:outcome) { :already_had }

      before do
        vaccination_record.update!(
          nhs_immunisations_api_sync_pending_at: nil,
          nhs_immunisations_api_synced_at: nil
        )
      end

      it "returns :not_synced" do
        expect(sync_status).to eq(:not_synced)
      end
    end

    context "when record was a historic vaccination" do
      let(:session) { nil }

      before do
        vaccination_record.update!(
          nhs_immunisations_api_sync_pending_at: nil,
          nhs_immunisations_api_synced_at: nil
        )
      end

      it "returns :not_synced" do
        expect(sync_status).to eq(:not_synced)
      end
    end

    context "when record has not been synced yet, but will eventually be" do
      before do
        vaccination_record.update!(
          nhs_immunisations_api_sync_pending_at: nil,
          nhs_immunisations_api_synced_at: nil
        )
      end

      it "returns :pending" do
        expect(sync_status).to eq(:pending)
      end
    end

    context "when record is pending removal from API because changed to not administered" do
      before do
        vaccination_record.update!(
          nhs_immunisations_api_sync_pending_at: 1.hour.ago,
          nhs_immunisations_api_synced_at: 1.day.ago
        )

        allow(vaccination_record).to receive(:administered?).and_return(false)
      end

      it "returns :not_synced" do
        expect(sync_status).to eq(:not_synced)
      end
    end

    context "when record has been successfully removed from API, after being changed to not administered" do
      before do
        vaccination_record.update!(
          nhs_immunisations_api_sync_pending_at: 2.hours.ago,
          nhs_immunisations_api_synced_at: 1.hour.ago
        )

        allow(vaccination_record).to receive(:administered?).and_return(false)
      end

      it "returns :not_synced" do
        expect(sync_status).to eq(:not_synced)
      end
    end

    context "when record has been unsuccessfully removed from API, after being changed to not administered" do
      before do
        vaccination_record.update!(
          nhs_immunisations_api_sync_pending_at: 25.hours.ago,
          nhs_immunisations_api_synced_at: 2.days.ago
        )

        allow(vaccination_record).to receive(:administered?).and_return(false)
      end

      it "returns :not_synced" do
        expect(sync_status).to eq(:not_synced)
      end
    end
  end
end
