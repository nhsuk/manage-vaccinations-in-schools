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

    context "with a normal school session" do
      let(:send_consent_requests_at) {}
      let(:days_before_consent_reminders) { 7 }
      let(:session) do
        create(
          :session,
          programmes: [flu],
          academic_year: AcademicYear.pending,
          dates:,
          send_consent_requests_at:,
          days_before_consent_reminders:,
          team:,
          location:
        )
      end

      context "with a specific unscheduled session" do
        before { described_class.perform_now([session]) }

        let(:dates) { [] }
        let(:days_before_consent_reminders) { nil }

        it { should have_received(:perform_bulk).once.with([[patient.id]]) }
      end

      context "session with dates in the future" do
        before { described_class.perform_now }

        let(:dates) { [7.days.from_now] }
        let(:send_consent_requests_at) { 14.days.ago }

        it { should have_received(:perform_bulk).once.with([[patient.id]]) }

        context "clinic session" do
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
        let(:send_consent_requests_at) { 30.days.ago }

        it { should_not have_received(:perform_bulk) }
      end

      context "session with dates in the past and the future",
              within_academic_year: {
                from_start: 7.days
              } do
        before { described_class.perform_now }

        let(:send_consent_requests_at) { 28.days.ago }
        let(:dates) { [7.days.ago, 7.days.from_now] }

        it { should have_received(:perform_bulk).exactly(:once) }
      end

      context "session with send_invitations_at in the future" do
        before { described_class.perform_now }

        let(:send_consent_requests_at) { 2.days.from_now }
        let(:dates) { [17.days.from_now] }

        it { should have_received(:perform_bulk).exactly(:once) }
      end

      context "session with send_consent_requests_at too far in the future" do
        let(:send_consent_requests_at) { 3.days.from_now }
        let(:dates) { [17.days.from_now] }

        it { should_not have_received(:perform_bulk) }
      end
    end

    shared_examples "notification date logic" do |notification_date_field|
      context "with notification date within threshold" do
        let(:session) do
          session_attributes = {
            programmes: [flu],
            academic_year: AcademicYear.pending,
            dates:,
            team:,
            location:
          }

          # Set the appropriate notification date field
          if notification_date_field == :send_invitations_at
            session_attributes[:send_invitations_at] = 1.day.from_now
            session_attributes[:send_consent_requests_at] = nil
          else
            session_attributes[:send_invitations_at] = nil
            session_attributes[:send_consent_requests_at] = 1.day.from_now
            session_attributes[:days_before_consent_reminders] = 7
          end

          create(:session, session_attributes)
        end

        before { described_class.perform_now }

        it "includes the session" do
          expect(SearchVaccinationRecordsInNHSJob).to have_received(
            :perform_bulk
          ).with([patient.id].zip)
        end
      end

      context "with notification date too far in future" do
        let(:session) do
          session_attributes = {
            programmes: [flu],
            academic_year: AcademicYear.pending,
            dates:,
            team:,
            location:
          }

          # Set the appropriate notification date field
          if notification_date_field == :send_invitations_at
            session_attributes[:send_invitations_at] = 3.days.from_now
            session_attributes[:send_consent_requests_at] = nil
          else
            session_attributes[:send_invitations_at] = nil
            session_attributes[:send_consent_requests_at] = 3.days.from_now
            session_attributes[:days_before_consent_reminders] = 7
          end

          create(:session, session_attributes)
        end

        before { described_class.perform_now }

        it "excludes the session" do
          expect(SearchVaccinationRecordsInNHSJob).not_to have_received(
            :perform_bulk
          )
        end
      end
    end

    context "testing notification date logic for different location types" do
      let(:dates) { [30.days.from_now] }

      context "generic clinic sessions" do
        let(:location) { create(:generic_clinic, team:, programmes: [flu]) }
        let(:school) { create(:school, team:, programmes: [flu]) }

        include_examples "notification date logic", :send_invitations_at
      end

      context "school sessions" do
        let(:location) { create(:school, team:, programmes: [flu]) }
        let(:school) { location }

        include_examples "notification date logic", :send_consent_requests_at
      end

      context "mixed session types" do
        let(:generic_clinic) do
          create(:generic_clinic, team:, programmes: [flu])
        end
        let(:school_location) { create(:school, team:, programmes: [flu]) }

        let(:generic_clinic_session) do
          create(
            :session,
            programmes: [flu],
            academic_year: AcademicYear.pending,
            dates:,
            send_invitations_at: 1.day.from_now,
            send_consent_requests_at: nil,
            days_before_consent_reminders: nil,
            team:,
            location: generic_clinic
          )
        end

        let(:school_session) do
          create(
            :session,
            programmes: [flu],
            academic_year: AcademicYear.pending,
            dates:,
            send_invitations_at: nil,
            send_consent_requests_at: 1.day.from_now,
            days_before_consent_reminders: 7,
            team:,
            location: school_location
          )
        end

        let!(:patient) do
          create(:patient, team:, school:, session: generic_clinic_session)
        end
        let!(:second_patient) do
          create(:patient, team:, school:, session: school_session)
        end

        before { described_class.perform_now }

        it "includes all sessions when their respective notification dates are within threshold" do
          expect(SearchVaccinationRecordsInNHSJob).to have_received(
            :perform_bulk
          ).with([patient.id].zip)

          expect(SearchVaccinationRecordsInNHSJob).to have_received(
            :perform_bulk
          ).with([second_patient.id].zip)
        end
      end
    end
  end
end
