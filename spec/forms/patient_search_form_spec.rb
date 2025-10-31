# frozen_string_literal: true

describe PatientSearchForm do
  subject(:form) do
    described_class.new(
      current_user:,
      request_session:,
      request_path:,
      session:,
      **params
    )
  end

  around { |example| travel_to(Date.new(2025, 7, 31)) { example.run } }

  let(:current_user) { create(:user, teams: [team]) }
  let(:request_session) { {} }
  let(:request_path) { "/patients" }
  let(:session) { nil }

  let(:programme) { create(:programme, :flu) }
  let(:programmes) { [programme] }
  let(:team) { create(:team, programmes:) }

  let(:aged_out_of_programmes) { nil }
  let(:archived) { nil }
  let(:consent_statuses) { nil }
  let(:date_of_birth_day) { Date.current.day }
  let(:date_of_birth_month) { Date.current.month }
  let(:date_of_birth_year) { Date.current.year }
  let(:missing_nhs_number) { true }
  let(:vaccination_status) { nil }
  let(:programme_types) { nil }
  let(:q) { "query" }
  let(:register_status) { nil }
  let(:triage_status) { nil }
  let(:vaccine_criteria) { nil }
  let(:still_to_vaccinate) { nil }
  let(:patient_specific_direction_status) { nil }
  let(:year_groups) { %w[8 9 10 11] }

  let(:params) do
    {
      aged_out_of_programmes:,
      archived:,
      consent_statuses:,
      date_of_birth_day:,
      date_of_birth_month:,
      date_of_birth_year:,
      missing_nhs_number:,
      vaccination_status:,
      still_to_vaccinate:,
      patient_specific_direction_status:,
      programme_types:,
      q:,
      register_status:,
      triage_status:,
      vaccine_criteria:,
      year_groups:
    }
  end

  let(:empty_params) { {} }

  describe "#apply" do
    let(:scope) { Patient.all }

    let(:session_for_patients) { create(:session, team:, programmes:) }

    it "doesn't raise an error" do
      expect { form.apply(scope) }.not_to raise_error
    end

    context "filtering on aged out of programmes" do
      let(:consent_statuses) { nil }
      let(:date_of_birth_day) { nil }
      let(:date_of_birth_month) { nil }
      let(:date_of_birth_year) { nil }
      let(:missing_nhs_number) { nil }
      let(:vaccination_status) { nil }
      let(:q) { nil }
      let(:register_status) { nil }
      let(:triage_status) { nil }
      let(:year_groups) { nil }

      let(:programmes) { [create(:programme, :flu)] }
      let(:location) do
        create(:school, programmes:, gias_year_groups: [11, 12])
      end
      let(:session_for_patients) { create(:session, location:, programmes:) }

      let!(:aged_out_patient) do
        create(:patient, session: session_for_patients, year_group: 12)
      end
      let!(:not_aged_out_patient) do
        create(:patient, session: session_for_patients, year_group: 11)
      end

      context "when not filtering on aged out patients" do
        let(:aged_out_of_programmes) { nil }

        it "includes the not aged out patient" do
          expect(form.apply(scope)).to include(not_aged_out_patient)
        end

        it "doesn't include the aged out patient" do
          expect(form.apply(scope)).not_to include(aged_out_patient)
        end
      end

      context "when filtering on aged out patients" do
        let(:aged_out_of_programmes) { true }

        it "doesn't include the not aged out patient" do
          expect(form.apply(scope)).not_to include(not_aged_out_patient)
        end

        it "includes the aged out patient" do
          expect(form.apply(scope)).to include(aged_out_patient)
        end
      end
    end

    context "filtering on archived" do
      let(:consent_statuses) { nil }
      let(:date_of_birth_day) { nil }
      let(:date_of_birth_month) { nil }
      let(:date_of_birth_year) { nil }
      let(:missing_nhs_number) { nil }
      let(:vaccination_status) { nil }
      let(:q) { nil }
      let(:register_status) { nil }
      let(:triage_status) { nil }
      let(:year_groups) { nil }

      let!(:unarchived_patient) do
        create(:patient, session: session_for_patients)
      end
      let!(:archived_patient) { create(:patient) }

      before do
        create(:archive_reason, :deceased, team:, patient: archived_patient)
      end

      context "when not filtering on archived patients" do
        let(:archived) { nil }

        it "includes the unarchived patient" do
          expect(form.apply(scope)).to include(unarchived_patient)
        end

        it "doesn't include the archived patient" do
          expect(form.apply(scope)).not_to include(archived_patient)
        end
      end

      context "when filtering on archived patients" do
        let(:archived) { true }

        it "doesn't include the unarchived patient" do
          expect(form.apply(scope)).not_to include(unarchived_patient)
        end

        it "includes the archived patient" do
          expect(form.apply(scope)).to include(archived_patient)
        end
      end
    end

    context "filtering on date of birth" do
      let(:consent_statuses) { nil }
      let(:date_of_birth_day) { nil }
      let(:date_of_birth_month) { nil }
      let(:date_of_birth_year) { nil }
      let(:missing_nhs_number) { nil }
      let(:vaccination_status) { nil }
      let(:q) { nil }
      let(:register_status) { nil }
      let(:triage_status) { nil }
      let(:year_groups) { nil }

      let(:patient) do
        create(
          :patient,
          session: session_for_patients,
          date_of_birth: Date.new(2000, 1, 1)
        )
      end

      context "with only a year specified" do
        let(:date_of_birth_year) { 2000 }

        it "includes the patient" do
          expect(form.apply(scope)).to include(patient)
        end
      end

      context "with only a month specified" do
        let(:date_of_birth_month) { 1 }

        it "includes the patient" do
          expect(form.apply(scope)).to include(patient)
        end
      end

      context "with only a day specified" do
        let(:date_of_birth_day) { 1 }

        it "includes the patient" do
          expect(form.apply(scope)).to include(patient)
        end
      end

      context "with all parts specified" do
        let(:date_of_birth_year) { 2000 }
        let(:date_of_birth_month) { 1 }
        let(:date_of_birth_day) { 1 }

        it "includes the patient" do
          expect(form.apply(scope)).to include(patient)
        end
      end
    end

    context "filtering on consent status" do
      let(:consent_statuses) { %w[given refused] }
      let(:date_of_birth_day) { nil }
      let(:date_of_birth_month) { nil }
      let(:date_of_birth_year) { nil }
      let(:missing_nhs_number) { nil }
      let(:vaccination_status) { nil }
      let(:programme_types) { programmes.map(&:type) }
      let(:q) { nil }
      let(:register_status) { nil }
      let(:triage_status) { nil }
      let(:year_groups) { nil }

      let(:session) { session_for_patients }

      it "filters on consent status" do
        patient_given =
          create(:patient, :consent_given_triage_not_needed, session:)

        patient_refused = create(:patient, :consent_refused, session:)

        expect(form.apply(scope)).to contain_exactly(
          patient_given,
          patient_refused
        )
      end

      context "with nasal" do
        let(:consent_statuses) { %w[given_nasal] }

        it "filters on consent status" do
          patient_given_nasal =
            create(
              :patient,
              :consent_given_nasal_only_triage_not_needed,
              session:
            )

          create(
            :patient,
            :consent_given_injection_only_triage_not_needed,
            session:
          )

          expect(form.apply(scope)).to contain_exactly(patient_given_nasal)
        end
      end

      context "with injection without gelatine" do
        let(:consent_statuses) { %w[given_injection_without_gelatine] }

        it "filters on consent status" do
          patient_given_without_gelatine =
            create(
              :patient,
              :consent_given_without_gelatine_triage_not_needed,
              session:
            )

          create(:patient, :consent_given_triage_not_needed, session:)

          expect(form.apply(scope)).to contain_exactly(
            patient_given_without_gelatine
          )
        end
      end

      context "with nasal and injection without gelatine" do
        let(:consent_statuses) do
          %w[given_nasal given_injection_without_gelatine]
        end

        it "filters on consent status" do
          patient_given_nasal =
            create(
              :patient,
              :consent_given_nasal_only_triage_not_needed,
              session:
            )

          patient_given_without_gelatine =
            create(
              :patient,
              :consent_given_without_gelatine_triage_not_needed,
              session:
            )

          create(:patient, :consent_given_triage_not_needed, session:)

          expect(form.apply(scope)).to contain_exactly(
            patient_given_nasal,
            patient_given_without_gelatine
          )
        end
      end
    end

    context "filtering on programmes" do
      let(:consent_status) { nil }
      let(:date_of_birth_day) { nil }
      let(:date_of_birth_month) { nil }
      let(:date_of_birth_year) { nil }
      let(:missing_nhs_number) { nil }
      let(:vaccination_status) { nil }
      let(:programme_types) { programmes.map(&:type) }
      let(:q) { nil }
      let(:register_status) { nil }
      let(:triage_status) { nil }
      let(:year_groups) { nil }

      let(:programme) { create(:programme, :menacwy) }
      let(:programmes) { [programme] }

      context "with a patient eligible for the programme" do
        let(:patient) { create(:patient, session: session_for_patients) }

        it "is included" do
          expect(form.apply(scope)).to include(patient)
        end
      end

      context "with a patient not eligible for the programme" do
        let(:patient) { create(:patient, year_group: 8) }

        it "is not included" do
          expect(form.apply(scope)).not_to include(patient)
        end
      end
    end

    context "filtering on programme status" do
      let(:consent_statuses) { nil }
      let(:date_of_birth_day) { nil }
      let(:date_of_birth_month) { nil }
      let(:date_of_birth_year) { nil }
      let(:missing_nhs_number) { nil }
      let(:vaccination_status) { "vaccinated" }
      let(:programme_types) { programmes.map(&:type) }
      let(:q) { nil }
      let(:register_status) { nil }
      let(:triage_status) { nil }
      let(:year_groups) { nil }

      it "filters on programme status" do
        patient =
          create(
            :patient,
            :vaccinated,
            programmes:,
            session: session_for_patients
          )

        expect(form.apply(scope)).to include(patient)
      end
    end

    context "filtering on register status" do
      let(:consent_statuses) { nil }
      let(:date_of_birth_day) { nil }
      let(:date_of_birth_month) { nil }
      let(:date_of_birth_year) { nil }
      let(:missing_nhs_number) { nil }
      let(:vaccination_status) { nil }
      let(:q) { nil }
      let(:register_status) { "attending" }
      let(:triage_status) { nil }
      let(:year_groups) { nil }

      let(:session) { session_for_patients }

      it "filters on register status" do
        patient = create(:patient, :in_attendance, session:)
        expect(form.apply(scope)).to include(patient)
      end
    end

    context "filtering on triage status" do
      let(:consent_statuses) { nil }
      let(:date_of_birth_day) { nil }
      let(:date_of_birth_month) { nil }
      let(:date_of_birth_year) { nil }
      let(:missing_nhs_number) { nil }
      let(:vaccination_status) { nil }
      let(:programme_types) { programmes.map(&:type) }
      let(:q) { nil }
      let(:register_status) { nil }
      let(:triage_status) { "required" }
      let(:year_groups) { nil }

      let(:session) { session_for_patients }

      it "filters on triage status" do
        patient = create(:patient, :consent_given_triage_needed, session:)

        expect(form.apply(scope)).to include(patient)
      end

      context "with nasal" do
        let(:triage_status) { "safe_to_vaccinate_nasal" }

        it "filters on triage status" do
          patient_safe_to_vaccinate_nasal =
            create(
              :patient,
              :consent_given_nasal_triage_safe_to_vaccinate_nasal,
              session:
            )

          create(
            :patient,
            :consent_given_injection_and_nasal_triage_safe_to_vaccinate_injection,
            session:
          )

          expect(form.apply(scope)).to contain_exactly(
            patient_safe_to_vaccinate_nasal
          )
        end
      end

      context "with injection without gelatine" do
        let(:triage_status) { "safe_to_vaccinate_injection_without_gelatine" }

        it "filters on consent status" do
          patient_safe_to_vaccinate_injection_without_gelatine =
            create(
              :patient,
              :consent_given_injection_and_nasal_triage_safe_to_vaccinate_injection,
              session:
            )

          create(
            :patient,
            :consent_given_nasal_triage_safe_to_vaccinate_nasal,
            session:
          )

          expect(form.apply(scope)).to contain_exactly(
            patient_safe_to_vaccinate_injection_without_gelatine
          )
        end
      end
    end

    context "filtering on patient specific direction status" do
      let(:consent_statuses) { nil }
      let(:date_of_birth_day) { nil }
      let(:date_of_birth_month) { nil }
      let(:date_of_birth_year) { nil }
      let(:missing_nhs_number) { nil }
      let(:vaccination_status) { nil }
      let(:programme_types) { nil }
      let(:q) { nil }
      let(:register_status) { nil }
      let(:triage_status) { nil }
      let(:year_groups) { nil }

      let(:session) { session_for_patients }

      let!(:patient_with_psd) { create(:patient, session:) }
      let!(:patient_without_psd) { create(:patient, session:) }

      before do
        create(
          :patient_specific_direction,
          patient: patient_with_psd,
          programme: programmes.first,
          team:
        )
      end

      context "when status is 'added'" do
        let(:patient_specific_direction_status) { "added" }

        it "finds the patient with the PSD" do
          expect(form.apply(scope)).to contain_exactly(patient_with_psd)
        end
      end

      context "when status is 'not_added'" do
        let(:patient_specific_direction_status) { "not_added" }

        it "finds the patient that has no PSD" do
          expect(form.apply(scope)).to contain_exactly(patient_without_psd)
        end
      end
    end

    context "filtering on vaccine criteria" do
      let(:consent_statuses) { nil }
      let(:date_of_birth_day) { nil }
      let(:date_of_birth_month) { nil }
      let(:date_of_birth_year) { nil }
      let(:missing_nhs_number) { nil }
      let(:vaccination_status) { nil }
      let(:programme_types) { programmes.map(&:type) }
      let(:q) { nil }
      let(:register_status) { nil }
      let(:triage_status) { nil }
      let(:vaccine_criteria) { "nasal" }
      let(:year_groups) { nil }

      let(:session) { session_for_patients }

      it "filters on vaccine method" do
        nasal_patient =
          create(:patient, :consent_given_triage_not_needed, session:)

        nasal_patient.consent_statuses.first.update!(
          vaccine_methods: %w[nasal injection]
        )

        _nasal_only_different_programme_patient =
          create(
            :patient,
            :consent_given_triage_not_needed,
            programmes: [create(:programme, :hpv)]
          )

        _injection_only_patient =
          create(:patient, :consent_given_triage_not_needed, session:)

        injection_primary_patient =
          create(:patient, :consent_given_triage_not_needed, session:)

        injection_primary_patient.consent_statuses.first.update!(
          vaccine_methods: %w[injection nasal]
        )

        expect(form.apply(scope)).to contain_exactly(nasal_patient)
      end
    end

    context "searching on name" do
      let(:consent_statuses) { nil }
      let(:date_of_birth_day) { nil }
      let(:date_of_birth_month) { nil }
      let(:date_of_birth_year) { nil }
      let(:missing_nhs_number) { nil }
      let(:vaccination_status) { nil }
      let(:q) { nil }
      let(:register_status) { nil }
      let(:triage_status) { nil }
      let(:year_groups) { nil }

      let(:patient_a) do
        create(
          :patient,
          given_name: "Harry",
          family_name: "Potter",
          session: session_for_patients
        )
      end
      let(:patient_b) do
        create(
          :patient,
          given_name: "Hari",
          family_name: "Potter",
          session: session_for_patients
        )
      end
      let(:patient_c) do
        create(
          :patient,
          given_name: "Arry",
          family_name: "Pott",
          session: session_for_patients
        )
      end
      let(:patient_d) do
        create(
          :patient,
          given_name: "Ron",
          family_name: "Weasley",
          session: session_for_patients
        )
      end
      let(:patient_e) do
        create(
          :patient,
          given_name: "Ginny",
          family_name: "Weasley",
          session: session_for_patients
        )
      end

      context "with no search query" do
        let(:q) { nil }

        it "sorts alphabetically by name" do
          expect(form.apply(scope)).to eq(
            [patient_c, patient_b, patient_a, patient_e, patient_d]
          )
        end
      end

      context "with some search query" do
        let(:q) { "Harry Potter" }

        it "sorts by similarity" do
          expect(form.apply(scope)).to eq([patient_a, patient_b, patient_c])
        end
      end
    end

    context "when still_to_vaccinate is true" do
      let(:consent_statuses) { nil }
      let(:date_of_birth_day) { nil }
      let(:date_of_birth_month) { nil }
      let(:date_of_birth_year) { nil }
      let(:missing_nhs_number) { nil }
      let(:vaccination_status) { nil }
      let(:programme_types) { nil }
      let(:q) { nil }
      let(:register_status) { nil }
      let(:triage_status) { nil }
      let(:year_groups) { nil }
      let(:still_to_vaccinate) { "1" }

      let(:session) { session_for_patients }

      let(:patient_a) do
        create(
          :patient,
          given_name: "Harry",
          family_name: "Potter",
          session: session_for_patients
        )
      end

      let(:patient_b) do
        create(
          :patient,
          given_name: "Hari",
          family_name: "Potter",
          session: session_for_patients
        )
      end

      before do
        create(
          :patient_consent_status,
          :given_injection_only,
          programme:,
          patient: patient_a
        )
      end

      it "returns patient A" do
        expect(form.apply(scope)).to eq([patient_a])
      end

      it "does not return patient B" do
        expect(form.apply(scope)).not_to include(patient_b)
      end
    end
  end

  describe "session filter persistence" do
    let(:another_path) { "/another-path" }

    context "when _clear param is present" do
      it "only clears filters for the current path" do
        described_class.new(
          current_user:,
          request_path:,
          request_session:,
          "q" => "John"
        )

        described_class.new(
          current_user:,
          request_path: another_path,
          request_session:,
          q: "Jane"
        )

        described_class.new(
          current_user:,
          request_path:,
          request_session:,
          "_clear" => "true"
        )

        form1 =
          described_class.new(current_user:, request_session:, request_path:)
        expect(form1.q).to be_nil

        form2 =
          described_class.new(
            current_user:,
            request_session:,
            request_path: another_path
          )
        expect(form2.q).to eq("Jane")
      end
    end

    context "when filters are present in params" do
      it "persists filters to be loaded in subsequent requests" do
        described_class.new(
          current_user:,
          q: "John",
          request_session:,
          request_path:
        )

        form =
          described_class.new(current_user:, request_session:, request_path:)
        expect(form.q).to eq("John")
      end

      it "overwrites previously stored filters" do
        described_class.new(
          current_user:,
          q: "John",
          request_session:,
          request_path:
        )

        form1 =
          described_class.new(
            current_user:,
            q: "Jane",
            request_session:,
            request_path:
          )
        expect(form1.q).to eq("Jane")

        form2 =
          described_class.new(current_user:, request_session:, request_path:)
        expect(form2.q).to eq("Jane")
      end

      it "overrides session filters when 'Any' option is selected (empty string)" do
        described_class.new(
          current_user:,
          consent_statuses: %w[given],
          request_session:,
          request_path:
        )

        form1 =
          described_class.new(current_user:, request_session:, request_path:)
        expect(form1.consent_statuses).to eq(%w[given])

        form2 =
          described_class.new(
            current_user:,
            consent_statuses: nil,
            request_session:,
            request_path:
          )
        expect(form2.consent_statuses).to eq([])

        form3 =
          described_class.new(current_user:, request_session:, request_path:)
        expect(form3.consent_statuses).to eq([])
      end
    end

    context "when no filters are present in params but exist in session" do
      before do
        described_class.new(
          current_user:,
          q: "John",
          year_groups: %w[8 11],
          consent_statuses: %w[given],
          request_session:,
          request_path:
        )
      end

      it "loads filters from the session" do
        form =
          described_class.new(current_user:, request_session:, request_path:)

        expect(form.q).to eq("John")
        expect(form.year_groups).to eq([8, 11])
        expect(form.consent_statuses).to eq(%w[given])
      end
    end

    context "with path-specific filters" do
      it "maintains separate filters for different paths" do
        described_class.new(
          current_user:,
          q: "John",
          request_session:,
          request_path:
        )
        described_class.new(
          current_user:,
          q: "Jane",
          request_session:,
          request_path: another_path
        )

        form1 =
          described_class.new(current_user:, request_session:, request_path:)
        expect(form1.q).to eq("John")

        form2 =
          described_class.new(
            current_user:,
            request_session:,
            request_path: another_path
          )
        expect(form2.q).to eq("Jane")
      end
    end
  end

  context "using PatientPolicy scope" do
    let(:q) { nil }
    let(:date_of_birth_day) { nil }
    let(:date_of_birth_month) { nil }
    let(:date_of_birth_year) { nil }
    let(:year_groups) { nil }
    let(:missing_nhs_number) { false }
    let(:programme_types) { programmes.map(&:type) }

    let(:team) { create(:team) }
    let(:programme) { create(:programme, :flu) }
    let(:subteam) { create(:subteam, team:) }
    let(:user) { create(:user, team:) }
    let(:patient) { create(:patient) }
    let(:scope) { PatientPolicy::Scope.new(user, Patient).resolve }

    context "when patient has a school move but is not part of the programme" do
      before do
        create(
          :school_move,
          :to_school,
          patient:,
          school: create(:school, subteam:)
        )
      end

      it "does not include the patient" do
        expect(form.apply(scope)).not_to include(patient)
      end
    end

    context "when patient has a vaccination record not associated with the programme" do
      before do
        create(
          :vaccination_record,
          patient:,
          performed_ods_code: team.organisation.ods_code,
          programme: create(:programme, :hpv)
        )
      end

      it "does not include the patient" do
        expect(form.apply(scope)).not_to include(patient)
      end
    end
  end
end
