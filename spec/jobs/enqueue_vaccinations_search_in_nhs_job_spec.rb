# frozen_string_literal: true

describe EnqueueVaccinationsSearchInNHSJob do
  include ActiveJob::TestHelper

  describe "#perform", :within_academic_year do
    before do
      Flipper.enable(:imms_api_enqueue_session_searches)
      allow(SearchVaccinationRecordsInNHSJob).to receive(:perform_bulk)

      # Ensure expectation patients and sessions are created before the job runs
      searchable_patients

      described_class.perform_now
    end

    let(:team) { create(:team) }
    let(:flu) { Programme.flu }

    let(:programmes) { [flu] }
    let(:gias_year_groups) { (0..11).to_a }
    let(:school) { create(:school, team:, programmes:, gias_year_groups:) }
    let(:clinic) { create(:generic_clinic, team:, programmes:) }

    let(:days_before_consent_reminders) { 7 }
    let(:session) do
      if location.generic_clinic?
        send_consent_requests_at = nil
        send_invitations_at = send_consent_requests_or_invitations_at
      else
        send_consent_requests_at = send_consent_requests_or_invitations_at
        send_invitations_at = nil
      end

      create(
        :session,
        programmes:,
        academic_year: AcademicYear.pending,
        dates:,
        send_consent_requests_at:,
        send_invitations_at:,
        days_before_consent_reminders:,
        team:,
        location:
      )
    end
    let(:searchable_patients) { [[create(:patient, team:, school:, session:)]] }

    shared_examples "behaviour before, during or after consent/invitation period" do
      subject { SearchVaccinationRecordsInNHSJob }

      context "before the consent or invitation period for the session",
              within_academic_year: {
                from_start: 30.days
              } do
        let(:dates) { [30.days.from_now] }
        let(:send_consent_requests_or_invitations_at) { 7.days.from_now }

        it { should_not have_received(:perform_bulk) }
      end

      context "within the consent or invitation period for the session",
              within_academic_year: {
                from_start: 7.days
              } do
        let(:dates) { [7.days.from_now] }
        let(:send_consent_requests_or_invitations_at) { 14.days.ago }

        it "performs searches on the session patients" do
          searchable_patients.each do |patients|
            expect(SearchVaccinationRecordsInNHSJob).to have_received(
              :perform_bulk
            ).once.with(patients.map(&:id).zip)
          end
        end
      end

      context "after the session dates",
              within_academic_year: {
                from_start: 7.days
              } do
        let(:dates) { [7.days.ago] }
        let(:send_consent_requests_or_invitations_at) { 30.days.ago }

        it { should_not have_received(:perform_bulk) }
      end

      context "in between multiple session dates",
              within_academic_year: {
                from_start: 7.days
              } do
        let(:dates) { [7.days.ago, 7.days.from_now] }
        let(:send_consent_requests_or_invitations_at) { 14.days.ago }

        it "performs searches on the session patients" do
          searchable_patients.each do |patients|
            expect(SearchVaccinationRecordsInNHSJob).to have_received(
              :perform_bulk
            ).once.with(patients.map(&:id).zip)
          end
        end
      end

      context "on the threshold of the consent or invitation period",
              within_academic_year: {
                from_start: 7.days
              } do
        let(:dates) { [30.days.from_now] }
        let(:send_consent_requests_or_invitations_at) { 2.days.from_now }

        it "performs searches on the session patients" do
          searchable_patients.each do |patients|
            expect(SearchVaccinationRecordsInNHSJob).to have_received(
              :perform_bulk
            ).once.with(patients.map(&:id).zip)
          end
        end
      end
    end

    context "with a normal school session" do
      let(:location) { school }

      include_examples "behaviour before, during or after consent/invitation period"
    end

    context "clinic session" do
      let(:location) { clinic }

      include_examples "behaviour before, during or after consent/invitation period"
    end

    context "mixed session types" do
      let(:searchable_patients) do
        clinic_session =
          create(
            :session,
            programmes:,
            academic_year: AcademicYear.pending,
            dates:,
            send_invitations_at: send_consent_requests_or_invitations_at,
            send_consent_requests_at: nil,
            days_before_consent_reminders: nil,
            team:,
            location: clinic
          )
        school_session =
          create(
            :session,
            programmes:,
            academic_year: AcademicYear.pending,
            dates:,
            send_invitations_at: nil,
            send_consent_requests_at: send_consent_requests_or_invitations_at,
            days_before_consent_reminders: 7,
            team:,
            location: school
          )
        [
          [create(:patient, team:, school:, session: clinic_session)],
          [create(:patient, team:, school:, session: school_session)]
        ]
      end

      include_examples "behaviour before, during or after consent/invitation period"
    end
  end
end
