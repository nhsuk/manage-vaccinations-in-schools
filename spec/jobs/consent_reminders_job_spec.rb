# frozen_string_literal: true

describe ConsentRemindersJob, type: :job do
  before do
    Flipper.enable(:scheduled_emails)
    ActiveJob::Base.queue_adapter.enqueued_jobs.clear
  end

  context "with draft and active sessions" do
    it "enqueues ConsentRemindersSessionBatchJob for each active sessions" do
      active_session =
        create(:session, draft: false, send_reminders_at: Time.zone.today)
      _draft_session =
        create(:session, draft: true, campaign: active_session.campaign)

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
        create(:session, draft: false, send_reminders_at: Time.zone.today)
      _later_session =
        create(
          :session,
          draft: false,
          send_reminders_at: 2.days.from_now,
          campaign: active_session.campaign
        )

      described_class.perform_now
      expect(ConsentRemindersSessionBatchJob).to have_been_enqueued.once
      expect(ConsentRemindersSessionBatchJob).to have_been_enqueued.with(
        active_session
      )
    end
  end
end
