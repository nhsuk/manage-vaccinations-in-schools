# frozen_string_literal: true

describe EnqueuePatientsAgedOutOfSchoolsJob do
  subject(:perform_now) { described_class.perform_now }

  let!(:school_with_team) { create(:school, team: create(:team)) }

  before { create(:school) }

  it "queues jobs for the schools with teams" do
    expect { perform_now }.to enqueue_sidekiq_job(
      PatientsAgedOutOfSchoolJob
    ).once.with(school_with_team.id)
  end
end
