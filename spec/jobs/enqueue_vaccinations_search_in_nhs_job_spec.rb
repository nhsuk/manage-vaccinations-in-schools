# frozen_string_literal: true

describe EnqueueVaccinationsSearchInNHSJob do
  include ActiveJob::TestHelper

  let(:team) { create(:team) }
  let(:flu) { create(:programme, :flu) }
  let(:location) { create(:school, team:, programmes: [flu]) }
  let(:school) { location }

  describe "#perform" do
    subject(:perform) { described_class.perform_now(sessions) }

    before { allow(SearchVaccinationRecordsInNHSJob).to receive(:perform_bulk) }

    context "when specific sessions are provided" do
      let(:session) do
        create(
          :session,
          programmes: [flu],
          academic_year: AcademicYear.pending,
          dates: [],
          send_consent_requests_at: nil,
          days_before_consent_reminders: nil,
          team:,
          location:
        )
      end

      let(:sessions) { [session] }

      let!(:patient) { create(:patient, team:, school:, session:) }

      it "enqueues searches only for the provided sessions" do
        perform

        expect(SearchVaccinationRecordsInNHSJob).to have_received(
          :perform_bulk
        ).once.with([[patient.id]])
      end
    end

    context "when no sessions are provided (uses scope)" do
      let!(:session_included) do
        create(
          :session,
          programmes: [flu],
          academic_year: AcademicYear.pending,
          dates: [7.days.from_now],
          send_consent_requests_at: 14.days.ago,
          days_before_consent_reminders: 7,
          team:,
          location:
        )
      end

      let!(:patient) do
        create(:patient, team:, school:, session: session_included)
      end

      let(:sessions) { nil }

      before do
        create(
          :session,
          programmes: [flu],
          academic_year: AcademicYear.pending,
          dates: [7.days.from_now],
          send_consent_requests_at: 3.days.from_now, # too far in future
          days_before_consent_reminders: 7,
          team:,
          location:
        )
      end

      it "enqueues searches for sessions returned by the scope and skips sessions with no patients" do
        perform

        expect(SearchVaccinationRecordsInNHSJob).to have_received(
          :perform_bulk
        ).once.with([[patient.id]])
      end
    end
  end
end
