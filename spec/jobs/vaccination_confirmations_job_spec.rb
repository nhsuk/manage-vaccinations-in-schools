# frozen_string_literal: true

describe VaccinationConfirmationsJob do
  let(:job) { described_class.new }

  describe "#perform" do
    subject(:perform) { job.perform }

    let(:programme) { create(:programme) }

    let(:existing_vaccination_record_already_sent) do
      create(
        :vaccination_record,
        :confirmation_sent,
        programme:,
        created_at: 3.days.ago
      )
    end

    let(:old_vaccination_record) do
      create(:vaccination_record, created_at: 2.days.ago, programme:)
    end

    let(:new_vaccination_record) { create(:vaccination_record, programme:) }

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

    before { allow(job).to receive(:send_vaccination_confirmation) }

    it "sends vaccination confirmations for approriate records" do
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
