# frozen_string_literal: true

describe EnqueueVaccinationsSearchInNHSJob do
  include ActiveJob::TestHelper

  describe "#perform", :within_academic_year do
    let(:flu) { Programme.flu }
    let(:programmes) { [flu] }
    let(:team) { create(:team) }
    let(:gias_year_groups) { (0..11).to_a }

    describe "session searches" do
      before do
        setup_feature_flag
        allow(SearchVaccinationRecordsInNHSJob).to receive(:perform_bulk)

        # Ensure expectation patients and sessions are created before the job runs
        searchable_patients
      end

      def setup_feature_flag
        Flipper.enable(:imms_api_enqueue_session_searches)
      end

      let(:school) { create(:school, team:, programmes:, gias_year_groups:) }
      let(:clinic) { create(:generic_clinic, team:, programmes:) }
      let(:location) { school }

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
      let(:searchable_patients) { [create(:patient, team:, school:, session:)] }

      context "with feature flag disabled" do
        def setup_feature_flag
          Flipper.disable(:imms_api_enqueue_session_searches)
        end

        let(:searchable_patients) { [] }

        it "does not perform searches on the session patients" do
          expect(SearchVaccinationRecordsInNHSJob).not_to have_received(
            :perform_bulk
          )
        end
      end

      shared_examples "behaviour before, during or after consent/invitation period" do
        context "before the consent or invitation period for the session",
                within_academic_year: {
                  from_start: 30.days
                } do
          let(:dates) { [30.days.from_now] }
          let(:send_consent_requests_or_invitations_at) { 7.days.from_now }

          it "does not perform any searches" do
            described_class.perform_now

            expect(SearchVaccinationRecordsInNHSJob).not_to have_received(
              :perform_bulk
            )
          end
        end

        context "within the consent or invitation period for the session",
                within_academic_year: {
                  from_start: 7.days
                } do
          let(:dates) { [7.days.from_now] }
          let(:send_consent_requests_or_invitations_at) { 14.days.ago }

          it "performs searches on the session patients" do
            described_class.perform_now

            expect(SearchVaccinationRecordsInNHSJob).to have_received(
              :perform_bulk
            ).once.with(searchable_patients.map(&:id).zip)
          end
        end

        context "after the session dates",
                within_academic_year: {
                  from_start: 7.days
                } do
          let(:dates) { [7.days.ago] }
          let(:send_consent_requests_or_invitations_at) { 30.days.ago }

          it "does not perform any searches" do
            described_class.perform_now

            expect(SearchVaccinationRecordsInNHSJob).not_to have_received(
              :perform_bulk
            )
          end
        end

        context "in between multiple session dates",
                within_academic_year: {
                  from_start: 7.days
                } do
          let(:dates) { [7.days.ago, 7.days.from_now] }
          let(:send_consent_requests_or_invitations_at) { 14.days.ago }

          it "performs searches on the session patients" do
            described_class.perform_now

            expect(SearchVaccinationRecordsInNHSJob).to have_received(
              :perform_bulk
            ).once.with(searchable_patients.map(&:id).zip)
          end
        end

        context "on the threshold of the consent or invitation period",
                within_academic_year: {
                  from_start: 7.days
                } do
          let(:dates) { [30.days.from_now] }
          let(:send_consent_requests_or_invitations_at) { 2.days.from_now }

          it "performs searches on the session patients" do
            described_class.perform_now

            expect(SearchVaccinationRecordsInNHSJob).to have_received(
              :perform_bulk
            ).once.with(searchable_patients.map(&:id).zip)
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
            create(:patient, team:, school:, session: clinic_session),
            create(:patient, team:, school:, session: school_session)
          ]
        end

        include_examples "behaviour before, during or after consent/invitation period"
      end
    end

    describe "doing the rolling searches" do
      before do
        setup_feature_flag
        setup_stubs

        # Ensure expectation patients are created before the job runs
        searchable_patients
      end

      def setup_stubs
        allow(SearchVaccinationRecordsInNHSJob).to receive(:perform_bulk)
      end

      def setup_feature_flag
        Flipper.enable(:imms_api_enqueue_rolling_searches)
      end

      let(:school) { create(:school, team:, programmes:, gias_year_groups:) }
      let(:patient_programme_vaccinations_searches) do
        [
          PatientProgrammeVaccinationsSearch.new(
            programme: flu,
            last_searched_at:
          )
        ]
      end
      let(:searchable_patients) do
        [
          create(
            :patient,
            team:,
            school:,
            patient_programme_vaccinations_searches:
          )
        ]
      end

      context "with the feature flag disabled" do
        def setup_feature_flag
          Flipper.disable(:imms_api_enqueue_rolling_searches)
        end

        let(:patient_programme_vaccinations_searches) { [] }

        it "does not perform a search on the patient" do
          described_class.perform_now

          expect(SearchVaccinationRecordsInNHSJob).not_to have_received(
            :perform_bulk
          )
        end
      end

      context "with a patient that has no previous searches" do
        let(:patient_programme_vaccinations_searches) { [] }

        it "performs a search on the patients" do
          described_class.perform_now

          expect(SearchVaccinationRecordsInNHSJob).to have_received(
            :perform_bulk
          ).once.with(searchable_patients.map(&:id).zip)
        end
      end

      context "with a patient that has searches 28 days ago or older" do
        let(:last_searched_at) { 28.days.ago }

        it "performs a search on the patient" do
          described_class.perform_now

          expect(SearchVaccinationRecordsInNHSJob).to have_received(
            :perform_bulk
          ).once.with(searchable_patients.map(&:id).zip)
        end
      end

      context "with a patient that has searches less-than 28 days" do
        let(:last_searched_at) { 27.days.ago }

        it "does not perform a search on the patient" do
          described_class.perform_now

          expect(SearchVaccinationRecordsInNHSJob).not_to have_received(
            :perform_bulk
          )
        end
      end

      context "with many patients that have searches 28 days ago or older" do
        let(:searchable_patients) do
          Patient.import(build_list(:patient, 50, team:, school:))
          Patient.all
        end

        context "and the batch size is less than the daily limit" do
          def setup_stubs
            allow(SearchVaccinationRecordsInNHSJob).to receive(:perform_bulk)

            allow_any_instance_of(EnqueueVaccinationsSearchInNHSJob).to receive(
              :daily_enqueue_size_limit
            ).and_return(1)
          end

          it "searches for 1/28th of the elligible patients" do
            described_class.perform_now

            expect(SearchVaccinationRecordsInNHSJob).to have_received(
              :perform_bulk
            ).once.with(searchable_patients.first(2).map(&:id).zip)
          end
        end

        context "and the batch size is greater than the daily limit" do
          let(:daily_limit) { 10 }

          def setup_stubs
            allow(SearchVaccinationRecordsInNHSJob).to receive(:perform_bulk)

            allow_any_instance_of(EnqueueVaccinationsSearchInNHSJob).to receive(
              :daily_enqueue_size_limit
            ).and_return(daily_limit)
          end

          it "searches for the daily limit of patients" do
            described_class.perform_now

            expect(SearchVaccinationRecordsInNHSJob).to have_received(
              :perform_bulk
            ).once.with(searchable_patients.first(daily_limit).map(&:id).zip)
          end
        end
      end
    end

    describe "when a patient shows up on both session and rolling searches" do
      before do
        Flipper.enable(:imms_api_enqueue_session_searches)
        Flipper.enable(:imms_api_enqueue_rolling_searches)

        allow(SearchVaccinationRecordsInNHSJob).to receive(:perform_bulk)

        patient
      end

      let(:school) { create(:school, team:, programmes:, gias_year_groups:) }
      let(:session) do
        create(
          :session,
          programmes:,
          academic_year: AcademicYear.pending,
          dates: [7.days.from_now],
          send_consent_requests_at: 7.days.ago,
          days_before_consent_reminders: 7,
          team:,
          location: school
        )
      end
      let(:patient) do
        create(
          :patient,
          team:,
          school:,
          session:,
          patient_programme_vaccinations_searches: [
            PatientProgrammeVaccinationsSearch.new(
              programme: flu,
              last_searched_at: 28.days.ago
            )
          ]
        )
      end

      it "only performs one search for the patient" do
        described_class.perform_now

        expect(SearchVaccinationRecordsInNHSJob).to have_received(
          :perform_bulk
        ).once.with([[patient.id]])
      end
    end
  end
end
