# frozen_string_literal: true

describe EnqueueSchoolConsentRequestsJob do
  subject(:perform_now) { described_class.perform_now }

  context "when session is unscheduled" do
    let(:session) { create(:session, :unscheduled) }

    it "doesn't queue any jobs" do
      expect { perform_now }.not_to have_enqueued_job(
        SendSchoolConsentRequestsJob
      )
    end
  end

  context "when requests should be sent in the future" do
    let(:session) do
      create(:session, send_consent_requests_at: 2.days.from_now)
    end

    it "doesn't queue any jobs" do
      expect { perform_now }.not_to have_enqueued_job(
        SendSchoolConsentRequestsJob
      )
    end
  end

  context "when requests should be sent today" do
    let(:session) do
      create(
        :session,
        date: 3.weeks.from_now.to_date,
        send_consent_requests_at: Date.current
      )
    end

    it "queues a job for the session" do
      expect { perform_now }.to have_enqueued_job(
        SendSchoolConsentRequestsJob
      ).with(session)
    end

    context "when location is a generic clinic" do
      let(:location) { create(:generic_clinic) }
      let(:session) do
        create(:session, location:, send_consent_requests_at: Date.current)
      end

      it "doesn't queue any jobs" do
        expect { perform_now }.not_to have_enqueued_job(
          SendSchoolConsentRequestsJob
        )
      end
    end
  end
end
