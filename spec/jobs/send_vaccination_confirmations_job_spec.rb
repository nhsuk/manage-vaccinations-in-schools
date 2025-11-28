# frozen_string_literal: true

describe SendVaccinationConfirmationsJob do
  let(:job) { described_class.new }

  describe "#perform" do
    subject(:perform) { job.perform }

    let(:programme) { Programme.sample }

    let(:existing_vaccination_record_already_sent) do
      create(
        :vaccination_record,
        :confirmation_sent,
        programme:,
        created_at: 3.days.ago
      )
    end

    let(:session) { create(:session, programmes: [programme]) }

    let(:old_vaccination_record) do
      create(:vaccination_record, created_at: 2.days.ago, programme:, session:)
    end

    let(:new_vaccination_record) do
      create(:vaccination_record, programme:, session:)
    end

    let(:new_vaccination_record_outside_session) do
      create(:vaccination_record, programme:)
    end

    let(:discarded_vaccination_record) do
      create(:vaccination_record, :discarded, programme:)
    end

    let(:historical_vaccination_record) do
      create(
        :vaccination_record,
        performed_at: Time.zone.local(2020, 1, 1),
        programme:
      )
    end

    before do
      allow(job).to receive(:send_vaccination_confirmation).and_call_original
    end

    it "sends vaccination confirmations for the appropriate records" do
      expect(job).not_to receive(:send_vaccination_confirmation).with(
        existing_vaccination_record_already_sent
      )
      expect(job).to receive(:send_vaccination_confirmation).with(
        old_vaccination_record
      )
      expect(job).to receive(:send_vaccination_confirmation).with(
        new_vaccination_record
      )
      expect(job).not_to receive(:send_vaccination_confirmation).with(
        new_vaccination_record_outside_session
      )
      expect(job).not_to receive(:send_vaccination_confirmation).with(
        discarded_vaccination_record
      )
      expect(job).not_to receive(:send_vaccination_confirmation).with(
        historical_vaccination_record
      )

      perform
    end

    it "records when the confirmation was sent" do
      freeze_time do
        expect { perform }.to change {
          new_vaccination_record.reload.confirmation_sent_at
        }.from(nil).to(Time.current)
      end
    end
  end
end
