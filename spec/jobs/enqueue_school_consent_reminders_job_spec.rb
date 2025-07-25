# frozen_string_literal: true

describe EnqueueSchoolConsentRemindersJob do
  subject(:perform_now) { described_class.perform_now }

  let(:programmes) { [create(:programme)] }
  let(:team) { create(:team, programmes:) }
  let(:location) { create(:school, team:) }

  let(:dates) { [Date.new(2024, 1, 12), Date.new(2024, 1, 15)] }

  let!(:session) do
    create(
      :session,
      dates:,
      send_consent_requests_at: dates.first - 3.weeks,
      days_before_consent_reminders: 7,
      location:,
      programmes:,
      team:
    )
  end

  around { |example| travel_to(today) { example.run } }

  context "two weeks before the first session" do
    let(:today) { dates.first - 2.weeks }

    it "doesn't queue any jobs" do
      expect { perform_now }.not_to have_enqueued_job(
        SendSchoolConsentRemindersJob
      )
    end
  end

  context "one week before the first session" do
    let(:today) { dates.first - 1.week }

    it "queues a job for the session" do
      expect { perform_now }.to have_enqueued_job(
        SendSchoolConsentRemindersJob
      ).with(session)
    end

    context "when location is a generic clinic" do
      let(:location) { create(:generic_clinic, team:) }

      it "doesn't queue any jobs" do
        expect { perform_now }.not_to have_enqueued_job(
          SendSchoolConsentRemindersJob
        )
      end
    end
  end

  context "one week before the second session" do
    let(:today) { dates.last - 1.week }

    it "queues a job for the session" do
      expect { perform_now }.to have_enqueued_job(
        SendSchoolConsentRemindersJob
      ).with(session)
    end

    context "when location is a generic clinic" do
      let(:location) { create(:generic_clinic, team:) }

      it "doesn't queue any jobs" do
        expect { perform_now }.not_to have_enqueued_job(
          SendSchoolConsentRemindersJob
        )
      end
    end
  end
end
