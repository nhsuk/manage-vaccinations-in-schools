# frozen_string_literal: true

describe EnqueueVaccinationsSearchInNHSJob do
  include ActiveJob::TestHelper

  let(:team) { create(:team) }
  let(:flu) { create(:programme, :flu) }
  let(:location) { create(:school, team:, programmes: [flu]) }
  let(:school) { location }
  let!(:patient) { create(:patient, team:, school:, session:) }

  describe "#perform", :within_academic_year do
    subject { SearchVaccinationRecordsInNHSJob }

    before { allow(SearchVaccinationRecordsInNHSJob).to receive(:perform_bulk) }

    let(:send_invitations_at) {}
    let!(:session) do
      create(
        :session,
        programmes: [flu],
        academic_year: AcademicYear.pending,
        dates:,
        send_invitations_at:,
        team:,
        location:
      )
    end

    context "with a specific session" do
      before { described_class.perform_now([session]) }

      let(:dates) { [] }

      it { should have_received(:perform_bulk).once.with([[patient.id]]) }
    end

    context "session with dates in the future" do
      before { described_class.perform_now }

      let(:dates) { [7.days.from_now] }
      let(:send_invitations_at) { 14.days.ago }

      it { should have_received(:perform_bulk).once.with([[patient.id]]) }

      context "community clinic session" do
        let(:location) { create(:community_clinic, team:, programmes: [flu]) }
        let(:school) { create(:school, team:, programmes: [flu]) }

        it { should have_received(:perform_bulk).exactly(:once) }
      end

      context "generic clinic session" do
        let(:location) { create(:generic_clinic, team:, programmes: [flu]) }
        let(:school) { create(:school, team:, programmes: [flu]) }

        it { should have_received(:perform_bulk).exactly(:once) }
      end
    end

    context "session with dates in the past",
            within_academic_year: {
              from_start: 7.days
            } do
      before { described_class.perform_now }

      let(:dates) { [7.days.ago] }

      it { should_not have_received(:perform_bulk) }
    end

    context "session with dates in the past and the future",
            within_academic_year: {
              from_start: 7.days
            } do
      before { described_class.perform_now }

      let(:send_invitations_at) { 28.days.ago }
      let(:dates) { [7.days.ago, 7.days.from_now] }

      it { should have_received(:perform_bulk).exactly(:once) }
    end

    context "session with send_invitations_at in the future" do
      before { described_class.perform_now }

      let(:send_invitations_at) { 2.days.from_now }
      let(:dates) { [17.days.from_now] }

      it { should have_received(:perform_bulk).exactly(:once) }
    end

    context "session with send_invitations_at too far in the future" do
      let(:send_invitations_at) { 3.days.from_now }
      let(:dates) { [17.days.from_now] }

      it { should_not have_received(:perform_bulk) }
    end
  end
end
