# frozen_string_literal: true

describe SessionRemindersJob do
  before do
    Flipper.enable(:scheduled_emails)
    ActiveJob::Base.queue_adapter.enqueued_jobs.clear
  end

  let(:campaign) { create(:campaign, :active) }

  it "enqueues SessionRemdindersJob for each session happening tomorrow" do
    tomorrow_session = create(:session, date: Date.tomorrow, campaign:)
    _todays_session = create(:session, date: Time.zone.today, campaign:)
    _yesterdays_session = create(:session, date: 2.days.from_now, campaign:)

    described_class.perform_now
    expect(SessionRemindersBatchJob).to have_been_enqueued.once
    expect(SessionRemindersBatchJob).to have_been_enqueued.with(
      tomorrow_session
    )
  end

  context "with draft and active sessions" do
    it "enqueues ConsentRemindersSessionBatchJob for each active sessions" do
      active_session = create(:session, date: Date.tomorrow, campaign:)
      _draft_session = create(:session, :draft, date: Date.tomorrow, campaign:)

      described_class.perform_now
      expect(SessionRemindersBatchJob).to have_been_enqueued.once
      expect(SessionRemindersBatchJob).to have_been_enqueued.with(
        active_session
      )
    end
  end
end
