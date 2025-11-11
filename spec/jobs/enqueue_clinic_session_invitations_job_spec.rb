# frozen_string_literal: true

describe EnqueueClinicSessionInvitationsJob do
  subject(:perform_now) { described_class.perform_now }

  around { |example| travel_to(Date.new(2025, 1, 1)) { example.run } }

  let(:programmes) { [Programme.hpv] }
  let(:team) { create(:team, programmes:) }
  let(:parents) { create_list(:parent, 2) }
  let(:patient) { create(:patient, parents:, year_group: 8) }
  let(:location) { create(:generic_clinic, team:) }

  before { create(:patient_location, patient:, session:) }

  context "for a scheduled clinic session in 3 weeks" do
    let(:date) { 3.weeks.from_now.to_date }
    let(:session) { create(:session, programmes:, date:, location:, team:) }

    it "queues a job for the session" do
      expect { perform_now }.to have_enqueued_job(
        SendClinicInitialInvitationsJob
      ).with(session)
    end
  end

  context "for a scheduled clinic session in 2 weeks" do
    let(:date) { 2.weeks.from_now.to_date }
    let(:session) { create(:session, programmes:, date:, location:, team:) }

    it "queues a job for the session" do
      expect { perform_now }.to have_enqueued_job(
        SendClinicInitialInvitationsJob
      ).with(session)
    end
  end

  context "for a scheduled clinic session in 4 weeks" do
    let(:date) { 4.weeks.from_now.to_date }
    let(:session) { create(:session, programmes:, date:, location:, team:) }

    it "doesn't queue any jobs" do
      expect { perform_now }.not_to have_enqueued_job(
        SendClinicInitialInvitationsJob
      )
    end
  end

  context "for a school session in 3 weeks time" do
    let(:location) { create(:school, team:) }

    let(:session) do
      create(
        :session,
        programmes:,
        date: 3.weeks.from_now.to_date,
        team:,
        location:
      )
    end

    it "doesn't queue any jobs" do
      expect { perform_now }.not_to have_enqueued_job(
        SendClinicInitialInvitationsJob
      )
    end
  end

  context "for a clinic session yesterday" do
    let(:session) do
      create(:session, :yesterday, programmes:, location:, team:)
    end

    it "doesn't queue any jobs" do
      expect { perform_now }.not_to have_enqueued_job(
        SendClinicInitialInvitationsJob
      )
    end
  end
end
