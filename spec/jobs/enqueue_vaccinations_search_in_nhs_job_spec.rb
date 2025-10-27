# frozen_string_literal: true

describe EnqueueVaccinationsSearchInNHSJob do
  include ActiveJob::TestHelper

  describe "#perform", :within_academic_year do
    let(:flu) { create(:programme, :flu) }
    let(:programmes) { [flu] }
    let(:team) { create(:team) }
    let(:gias_year_groups) { (0..11).to_a }
    let(:location) { school }
    let(:school) { create(:school, team:, programmes:) }
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
    let(:dates) { [14.days.from_now] }
    let(:send_consent_requests_or_invitations_at) { 7.days.ago }

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

      context "with sessions from previous academic years" do
        before do
          # The session searches only trigger for patients in sessions from the
          # current academic year, so these should not show up.
          old_session =
            create(
              :session,
              programmes: [flu],
              academic_year: AcademicYear.previous,
              dates: [20.days.from_now],
              send_consent_requests_at: 1.day.ago,
              team:
            )
          create(:patient, team:, session: old_session, year_group: 8)
        end

        let(:location) { school }

        include_examples "behaviour before, during or after consent/invitation period"
      end

      context "with sessions for non-searchable programmes" do
        before do
          # The session searches only trigger for patients in flu sessions, so
          # these should not show up.
          hpv = create(:programme, :hpv)
          hpv_location = create(:school, team:, programmes: [hpv])
          hpv_location.import_default_programme_year_groups!(
            [hpv],
            academic_year: AcademicYear.pending
          )
          hpv_session =
            create(
              :session,
              programmes: Programme.hpv,
              academic_year: AcademicYear.pending,
              dates: [20.days.from_now],
              send_consent_requests_at: 1.day.ago,
              team:,
              location: hpv_location
            )
          create(:patient, team:, school:, session: hpv_session)
        end

        let(:location) { school }

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
      let(:location) { school }
      let(:session) { create(:session, programmes:, team:, location:) }
      let(:patient_programme_vaccinations_searches) do
        [
          create(
            :patient_programme_vaccinations_search,
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
            session:,
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

      context "with many patients" do
        let(:last_searched_at) { 28.days.ago }
        let(:searchable_patients) do
          # Importing patients this way is significantly faster than creating
          # them with create / create_list. Not using a factory could end up
          # with broken tests, but since the expectations further down expect to
          # find at least 2 patients, I think it'll reliably stop working if the
          # underlying structure changes in the future so we won't end up with a
          # false-positive test.

          # TODO: Make this work (test is failing) and see if it's any faster.
          #       Or just trash it, initial testing doessn't show it's faster.
          # patients =
          #   build_stubbed_list(
          #     :patient,
          #     50,
          #     team:,
          #     school:,
          #     session:,
          #     patient_programme_vaccinations_searches:,
          #     patient_locations: [
          #       build(
          #         :patient_location,
          #         location_id: location.id,
          #         academic_year: AcademicYear.pending
          #       )
          #     ]
          #   )
          # allow(Patient).to receive(:all).and_return(
          #   Patient.none.tap do |relation|
          #     allow(relation).to receive(:to_a).and_return(patients)
          #   end
          # )
          # patients

          Patient.import(build_list(:patient, 50, team:, school:, session:))
          PatientLocation.import(
            Patient.all.map do
              {
                patient_id: it.id,
                location_id: location.id,
                academic_year: AcademicYear.pending
              }
            end
          )
          Patient.all
        end

        it "searches for 1/28th of the elligible patients" do
          described_class.perform_now

          expect(SearchVaccinationRecordsInNHSJob).to have_received(
            :perform_bulk
          ).once.with(searchable_patients.first(2).map(&:id).zip)
        end

        context "when most of the patients have had a search done recently" do
          before do
            PatientProgrammeVaccinationsSearch.import(
              (Patient.all - patients_with_older_searches).map do |patient|
                {
                  patient_id: patient.id,
                  programme_id: flu.id,
                  last_searched_at: 10.days.ago
                }
              end
            )

            PatientProgrammeVaccinationsSearch.import(
              patients_with_older_searches.map do |patient|
                {
                  patient_id: patient.id,
                  programme_id: flu.id,
                  last_searched_at: 30.days.ago
                }
              end
            )
          end

          let(:patients_with_older_searches) { searchable_patients.sample(5) }

          it "searches for 1/28th of the elligible patients" do
            # We're protecting against a regression here where we search for
            # 1/28th of the _remaining_ searchable patients, rather than 1/28th
            # of all the patients elligible for searching. If we do the former,
            # then we'll search for less and less patients over time.
            described_class.perform_now

            expect(SearchVaccinationRecordsInNHSJob).to have_received(
              :perform_bulk
            ).once do |args|
              expect(args.length).to eq(2)
              expect(patients_with_older_searches.map(&:id).zip).to include(
                *args
              )
            end

            # .once.with(patients_with_older_searches.first(2).map(&:id).zip)
          end
        end

        context "with patients with no searches or older searches" do
          before do
            patients =
              Patient.where.not(
                id: [patient_with_no_searches.id, patient_with_old_searches.id]
              )
            PatientProgrammeVaccinationsSearch.import(
              patients.map do |patient|
                {
                  patient_id: patient.id,
                  programme_id: flu.id,
                  last_searched_at: 30.days.ago
                }
              end
            )
            create(
              :patient_programme_vaccinations_search,
              patient: patient_with_old_searches,
              programme: flu,
              last_searched_at: 40.days.ago
            )
          end

          let(:patient_with_no_searches) { Patient.all.sample }
          let(:patient_with_old_searches) { Patient.all.sample }

          it "prioritises patients with no searches, then older searches" do
            described_class.perform_now

            expect(SearchVaccinationRecordsInNHSJob).to have_received(
              :perform_bulk
            ).once.with(
              [[patient_with_no_searches.id], [patient_with_old_searches.id]]
            )
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
