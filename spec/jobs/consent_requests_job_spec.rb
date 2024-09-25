# frozen_string_literal: true

describe ConsentRequestsJob, type: :job do
  before do
    Flipper.enable(:scheduled_emails)
    ActiveJob::Base.queue_adapter.enqueued_jobs.clear
  end

  let(:programme) { create(:programme) }

  context "with draft and active sessions" do
    it "enqueues ConsentRequestsSessionBatchJob for each active sessions" do
      active_session =
        create(:session, send_consent_requests_at: Time.zone.today, programme:)
      _unplanned_session = create(:session, date: nil, programme:)

      described_class.perform_now
      expect(ConsentRequestsSessionBatchJob).to have_been_enqueued.once
      expect(ConsentRequestsSessionBatchJob).to have_been_enqueued.with(
        active_session
      )
    end
  end

  context "with sessions set to send consent today and in the future" do
    it "enqueues ConsentRequestsSessionBatchJob for the session set to send consent today" do
      active_session =
        create(:session, send_consent_requests_at: Time.zone.today, programme:)
      _later_session =
        create(:session, send_consent_requests_at: 2.days.from_now, programme:)

      described_class.perform_now
      expect(ConsentRequestsSessionBatchJob).to have_been_enqueued.once
      expect(ConsentRequestsSessionBatchJob).to have_been_enqueued.with(
        active_session
      )
    end
  end
end
