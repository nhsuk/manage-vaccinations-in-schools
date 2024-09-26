# frozen_string_literal: true

describe ConsentRemindersJob, type: :job do
  before do
    Flipper.enable(:scheduled_emails)
    ActiveJob::Base.queue_adapter.enqueued_jobs.clear
  end

  let(:programme) { create(:programme) }

  context "with draft and active sessions" do
    it "enqueues ConsentRemindersSessionBatchJob for each active sessions" do
      active_session =
        create(:session, programme:, send_consent_reminders_at: Time.zone.today)
      _unscheduled_session = create(:session, :unscheduled, programme:)

      described_class.perform_now
      expect(ConsentRemindersSessionBatchJob).to have_been_enqueued.once
      expect(ConsentRemindersSessionBatchJob).to have_been_enqueued.with(
        active_session
      )
    end
  end

  context "with sessions set to send consent today and in the future" do
    it "enqueues ConsentRemindersSessionBatchJob for the session set to send consent today" do
      active_session =
        create(:session, programme:, send_consent_reminders_at: Time.zone.today)
      _later_session =
        create(:session, programme:, send_consent_reminders_at: 2.days.from_now)

      described_class.perform_now
      expect(ConsentRemindersSessionBatchJob).to have_been_enqueued.once
      expect(ConsentRemindersSessionBatchJob).to have_been_enqueued.with(
        active_session
      )
    end
  end
end
