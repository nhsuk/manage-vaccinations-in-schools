# frozen_string_literal: true

describe SearchForm do
  subject(:form) { described_class.new(**params, session:, request_path:) }

  let(:session) { {} }
  let(:request_path) { "/a-path" }

  let(:consent_statuses) { nil }
  let(:date_of_birth_day) { Date.current.day }
  let(:date_of_birth_month) { Date.current.month }
  let(:date_of_birth_year) { Date.current.year }
  let(:missing_nhs_number) { true }
  let(:programme_status) { nil }
  let(:q) { "query" }
  let(:register_status) { nil }
  let(:session_status) { nil }
  let(:triage_status) { nil }
  let(:year_groups) { %w[8 9 10 11] }

  let(:params) do
    {
      consent_statuses:,
      date_of_birth_day:,
      date_of_birth_month:,
      date_of_birth_year:,
      missing_nhs_number:,
      programme_status:,
      q:,
      register_status:,
      session_status:,
      triage_status:,
      year_groups:
    }
  end

  let(:empty_params) { {} }

  context "for patients" do
    let(:scope) { Patient.all }

    it "doesn't raise an error" do
      expect { form.apply(scope) }.not_to raise_error
    end

    context "filtering on date of birth" do
      let(:consent_statuses) { nil }
      let(:date_of_birth_day) { nil }
      let(:date_of_birth_month) { nil }
      let(:date_of_birth_year) { nil }
      let(:missing_nhs_number) { nil }
      let(:programme_status) { nil }
      let(:q) { nil }
      let(:register_status) { nil }
      let(:session_status) { nil }
      let(:triage_status) { nil }
      let(:year_groups) { nil }

      let(:patient) { create(:patient, date_of_birth: Date.new(2000, 1, 1)) }

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

    context "filtering on programme status" do
      let(:consent_statuses) { nil }
      let(:date_of_birth_day) { nil }
      let(:date_of_birth_month) { nil }
      let(:date_of_birth_year) { nil }
      let(:missing_nhs_number) { nil }
      let(:programme_status) { "vaccinated" }
      let(:q) { nil }
      let(:register_status) { nil }
      let(:session_status) { nil }
      let(:triage_status) { nil }
      let(:year_groups) { nil }

      let(:programme) { create(:programme) }

      it "filters on session status" do
        patient = create(:patient, :vaccinated, programmes: [programme])
        expect(form.apply(scope, programme:)).to include(patient)
      end
    end

    context "searching on name" do
      let(:consent_statuses) { nil }
      let(:date_of_birth_day) { nil }
      let(:date_of_birth_month) { nil }
      let(:date_of_birth_year) { nil }
      let(:missing_nhs_number) { nil }
      let(:programme_status) { nil }
      let(:q) { nil }
      let(:register_status) { nil }
      let(:session_status) { nil }
      let(:triage_status) { nil }
      let(:year_groups) { nil }

      let(:patient_a) do
        create(:patient, given_name: "Harry", family_name: "Potter")
      end
      let(:patient_b) do
        create(:patient, given_name: "Hari", family_name: "Potter")
      end
      let(:patient_c) do
        create(:patient, given_name: "Arry", family_name: "Pott")
      end
      let(:patient_d) do
        create(:patient, given_name: "Ron", family_name: "Weasley")
      end
      let(:patient_e) do
        create(:patient, given_name: "Ginny", family_name: "Weasley")
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
  end

  context "for patient sessions" do
    let(:scope) { PatientSession.all }

    it "doesn't raise an error" do
      expect { form.apply(scope) }.not_to raise_error
    end

    context "filtering on consent status" do
      let(:consent_statuses) { %w[given refused] }
      let(:date_of_birth_day) { nil }
      let(:date_of_birth_month) { nil }
      let(:date_of_birth_year) { nil }
      let(:missing_nhs_number) { nil }
      let(:programme_status) { nil }
      let(:q) { nil }
      let(:register_status) { nil }
      let(:triage_status) { nil }
      let(:year_groups) { nil }

      let(:programme) { create(:programme) }

      it "filters on consent status" do
        patient_session_given =
          create(
            :patient_session,
            :consent_given_triage_not_needed,
            programmes: [programme]
          )

        patient_session_refused =
          create(:patient_session, :consent_refused, programmes: [programme])

        expect(form.apply(scope, programme:)).to contain_exactly(
          patient_session_given,
          patient_session_refused
        )
      end
    end

    context "filtering on session status" do
      let(:consent_statuses) { nil }
      let(:date_of_birth_day) { nil }
      let(:date_of_birth_month) { nil }
      let(:date_of_birth_year) { nil }
      let(:missing_nhs_number) { nil }
      let(:programme_status) { nil }
      let(:q) { nil }
      let(:register_status) { nil }
      let(:session_status) { "vaccinated" }
      let(:triage_status) { nil }
      let(:year_groups) { nil }

      let(:programme) { create(:programme) }

      it "filters on session status" do
        patient_session =
          create(:patient_session, :vaccinated, programmes: [programme])
        expect(form.apply(scope, programme:)).to include(patient_session)
      end
    end

    context "filtering on register status" do
      let(:consent_statuses) { nil }
      let(:date_of_birth_day) { nil }
      let(:date_of_birth_month) { nil }
      let(:date_of_birth_year) { nil }
      let(:missing_nhs_number) { nil }
      let(:programme_status) { nil }
      let(:q) { nil }
      let(:register_status) { "attending" }
      let(:session_status) { nil }
      let(:triage_status) { nil }
      let(:year_groups) { nil }

      it "filters on register status" do
        patient_session = create(:patient_session, :in_attendance)
        expect(form.apply(scope)).to include(patient_session)
      end
    end

    context "filtering on triage status" do
      let(:consent_statuses) { nil }
      let(:date_of_birth_day) { nil }
      let(:date_of_birth_month) { nil }
      let(:date_of_birth_year) { nil }
      let(:missing_nhs_number) { nil }
      let(:programme_status) { nil }
      let(:q) { nil }
      let(:register_status) { nil }
      let(:session_status) { nil }
      let(:triage_status) { "required" }
      let(:year_groups) { nil }

      let(:programme) { create(:programme) }

      it "filters on triage status" do
        patient_session =
          create(
            :patient_session,
            :consent_given_triage_needed,
            programmes: [programme]
          )
        expect(form.apply(scope, programme:)).to include(patient_session)
      end
    end
  end

  describe "session filter persistence" do
    let(:another_path) { "/another-path" }

    context "when clear_filters param is present" do
      it "only clears filters for the current path" do
        described_class.new(q: "John", session:, request_path:)
        described_class.new(q: "Jane", session:, request_path: another_path)

        described_class.new(clear_filters: "true", session:, request_path:)

        form1 = described_class.new(**empty_params, session:, request_path:)
        expect(form1.q).to be_nil

        form2 =
          described_class.new(
            **empty_params,
            session:,
            request_path: another_path
          )
        expect(form2.q).to eq("Jane")
      end
    end

    context "when filters are present in params" do
      it "persists filters to be loaded in subsequent requests" do
        described_class.new(q: "John", session:, request_path:)

        form = described_class.new(**empty_params, session:, request_path:)
        expect(form.q).to eq("John")
      end

      it "overwrites previously stored filters" do
        described_class.new(q: "John", session:, request_path:)

        form1 = described_class.new(q: "Jane", session:, request_path:)
        expect(form1.q).to eq("Jane")

        form2 = described_class.new(**empty_params, session:, request_path:)
        expect(form2.q).to eq("Jane")
      end

      it "overrides session filters when 'Any' option is selected (empty string)" do
        described_class.new(
          consent_statuses: %w[given],
          session:,
          request_path:
        )

        form1 = described_class.new(**empty_params, session:, request_path:)
        expect(form1.consent_statuses).to eq(%w[given])

        form2 =
          described_class.new(consent_statuses: nil, session:, request_path:)
        expect(form2.consent_statuses).to eq([])

        form3 = described_class.new(**empty_params, session:, request_path:)
        expect(form3.consent_statuses).to eq([])
      end
    end

    context "when no filters are present in params but exist in session" do
      before do
        described_class.new(
          q: "John",
          year_groups: %w[8 11],
          consent_statuses: %w[given],
          session:,
          request_path:
        )
      end

      it "loads filters from the session" do
        form = described_class.new(**empty_params, session:, request_path:)

        expect(form.q).to eq("John")
        expect(form.year_groups).to eq([8, 11])
        expect(form.consent_statuses).to eq(%w[given])
      end
    end

    context "with path-specific filters" do
      it "maintains separate filters for different paths" do
        described_class.new(q: "John", session:, request_path:)
        described_class.new(q: "Jane", session:, request_path: another_path)

        form1 = described_class.new(**empty_params, session:, request_path:)
        expect(form1.q).to eq("John")

        form2 =
          described_class.new(
            **empty_params,
            session:,
            request_path: another_path
          )
        expect(form2.q).to eq("Jane")
      end
    end
  end
end
