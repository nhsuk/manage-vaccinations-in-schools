# frozen_string_literal: true

describe EnqueueSyncVaccinationRecordToNHS do
  context "when the feature flag is disabled" do
    before { Flipper.disable(:sync_vaccination_records_to_nhs_on_create) }

    let(:vaccination_record) { create(:vaccination_record) }

    it "does not enqueue the job" do
      expect {
        described_class.call(vaccination_record)
      }.not_to have_enqueued_job(SyncVaccinationRecordToNHSJob)
    end
  end

  context "when the feature flag is enabled" do
    before { Flipper.enable(:sync_vaccination_records_to_nhs_on_create) }

    let(:outcome) { "administered" }
    let(:programme) { create(:programme, type: "flu") }
    let(:session) { create(:session, programmes: [programme]) }
    let(:vaccination_record) do
      create(:vaccination_record, outcome:, programme:, session:)
    end

    context "with a single vaccination record" do
      it "enqueues the job if the vaccination record is elligible to sync" do
        expect {
          described_class.call(vaccination_record)
        }.to have_enqueued_job(SyncVaccinationRecordToNHSJob)
      end
    end

    context "with a discarded vaccination record" do
      before { vaccination_record.discard! }

      it "does not enqueue the job" do
        expect {
          described_class.call(vaccination_record)
        }.not_to have_enqueued_job(SyncVaccinationRecordToNHSJob)
      end
    end

    VaccinationRecord.defined_enums["outcome"].each_key do |outcome|
      next if outcome == "administered"

      context "when the vaccination record outcome is #{outcome}" do
        let(:outcome) { outcome }

        it "does not enqueue the job" do
          expect {
            described_class.call(vaccination_record)
          }.not_to have_enqueued_job(SyncVaccinationRecordToNHSJob)
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
          }.not_to have_enqueued_job(SyncVaccinationRecordToNHSJob)
        end
      end
    end

    context "with a vaccinaton record relation" do
      # The strategy is to create a vaccination record for each of the various
      # variations, and test that only the correct ones are allowed through

      before do
        # Generate historic vaccination record (no session)
        create(:vaccination_record, outcome:, programme:)

        # Generate vaccination records for all programme types
        Programme.defined_enums["type"].each_key do |programme_type|
          next if programme_type == "flu"
          programme = create(:programme, type: programme_type)
          create(:vaccination_record, outcome: "refused", session:, programme:)
        end

        # Generate vaccination records for all outcomes
        VaccinationRecord.defined_enums["outcome"].each_key do |outcome|
          next if outcome == "administered"
          create(:vaccination_record, outcome:, session:, programme:)
        end

        create(:vaccination_record, :discarded, outcome:, session:, programme:)
      end

      let(:flu_programme) { Programme.flu.first || create(:programme, :flu) }
      let(:hpv_programme) { Programme.hpv.first || create(:programme, :hpv) }
      let!(:flu_vaccination_record) do
        create(
          :vaccination_record,
          programme: flu_programme,
          session:,
          outcome: :administered
        )
      end
      let!(:hpv_vaccination_record) do
        create(
          :vaccination_record,
          programme: hpv_programme,
          session:,
          outcome: :administered
        )
      end

      it "enqueues the job for each eligible vaccination record" do
        expect {
          described_class.call(VaccinationRecord.all)
        }.to have_enqueued_job(SyncVaccinationRecordToNHSJob).exactly(2).times
      end

      it "enqueues the eligible flu job" do
        expect {
          described_class.call(VaccinationRecord.all)
        }.to have_enqueued_job(SyncVaccinationRecordToNHSJob).with(
          flu_vaccination_record
        )
      end

      it "enqueues the eligible hpv job" do
        expect {
          described_class.call(VaccinationRecord.all)
        }.to have_enqueued_job(SyncVaccinationRecordToNHSJob).with(
          hpv_vaccination_record
        )
      end
    end
  end
end
