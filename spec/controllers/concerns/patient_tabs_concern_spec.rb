# frozen_string_literal: true

describe PatientTabsConcern do
  subject { Class.new { include PatientTabsConcern }.new }

  let(:programme) { create(:programme) }
  let(:session) { create(:session, programme:) }

  let(:added_to_session) do
    create(:patient_session, :added_to_session, programme:, session:)
  end
  let(:consent_conflicts) do
    create(:patient_session, :consent_conflicting, programme:, session:)
  end
  let(:consent_given_triage_not_needed) do
    create(
      :patient_session,
      :consent_given_triage_not_needed,
      programme:,
      session:
    )
  end
  let(:consent_given_triage_needed) do
    create(:patient_session, :consent_given_triage_needed, programme:, session:)
  end
  let(:consent_refused) do
    create(:patient_session, :consent_refused, programme:, session:)
  end
  let(:delay_vaccination) do
    create(:patient_session, :delay_vaccination, programme:, session:)
  end
  let(:triaged_do_not_vaccinate) do
    create(:patient_session, :triaged_do_not_vaccinate, programme:, session:)
  end
  let(:triaged_kept_in_triage) do
    create(:patient_session, :triaged_kept_in_triage, programme:, session:)
  end
  let(:triaged_ready_to_vaccinate) do
    create(:patient_session, :triaged_ready_to_vaccinate, programme:, session:)
  end
  let(:unable_to_vaccinate) do
    create(:patient_session, :unable_to_vaccinate, programme:, session:)
  end
  let(:unable_to_vaccinate_not_gillick_competent) do
    create(
      :patient_session,
      :unable_to_vaccinate_not_gillick_competent,
      programme:,
      session:
    )
  end
  let(:vaccinated) do
    create(:patient_session, :vaccinated, programme:, session:)
  end

  let(:patient_sessions) do
    [
      added_to_session,
      consent_conflicts,
      consent_given_triage_not_needed,
      consent_given_triage_needed,
      consent_refused,
      delay_vaccination,
      triaged_do_not_vaccinate,
      triaged_kept_in_triage,
      triaged_ready_to_vaccinate,
      unable_to_vaccinate,
      unable_to_vaccinate_not_gillick_competent,
      vaccinated
    ]
  end

  describe "#group_patient_sessions_by_conditions" do
    it "groups patient sessions by conditions" do
      result =
        subject.group_patient_sessions_by_conditions(
          patient_sessions,
          section: :consents
        )

      expect(result).to eq(
        {
          consent_given: [
            consent_given_triage_not_needed,
            consent_given_triage_needed,
            delay_vaccination,
            triaged_do_not_vaccinate,
            triaged_kept_in_triage,
            triaged_ready_to_vaccinate,
            unable_to_vaccinate,
            unable_to_vaccinate_not_gillick_competent,
            vaccinated
          ],
          consent_refused: [consent_refused],
          conflicting_consent: [consent_conflicts],
          no_consent: [added_to_session]
        }.with_indifferent_access
      )
    end

    context "some of the groups are empty" do
      it "returns an empty array for all the empty groups" do
        result =
          subject.group_patient_sessions_by_conditions(
            [consent_given_triage_not_needed],
            section: :consents
          )

        expect(result).to eq(
          {
            consent_given: [consent_given_triage_not_needed],
            consent_refused: [],
            conflicting_consent: [],
            no_consent: []
          }.with_indifferent_access
        )
      end
    end
  end

  describe "#group_patient_sessions_by_states" do
    context "triage section" do
      it "groups patient sessions by triage states" do
        result =
          subject.group_patient_sessions_by_state(
            patient_sessions,
            section: :triage
          )

        expect(result).to eq(
          {
            needs_triage: [consent_given_triage_needed, triaged_kept_in_triage],
            triage_complete: [
              delay_vaccination,
              triaged_do_not_vaccinate,
              triaged_ready_to_vaccinate
            ],
            no_triage_needed: [
              consent_given_triage_not_needed,
              consent_refused,
              unable_to_vaccinate,
              unable_to_vaccinate_not_gillick_competent,
              vaccinated
            ]
          }.with_indifferent_access
        )
      end
    end

    context "vaccinations section" do
      it "groups patient sessions by vaccination states" do
        result =
          subject.group_patient_sessions_by_state(
            patient_sessions,
            section: :vaccinations
          )

        expect(result).to eq(
          {
            vaccinate: [
              consent_given_triage_not_needed,
              triaged_ready_to_vaccinate
            ],
            vaccinated: [vaccinated],
            could_not_vaccinate: [
              consent_conflicts,
              consent_refused,
              delay_vaccination,
              triaged_do_not_vaccinate,
              unable_to_vaccinate,
              unable_to_vaccinate_not_gillick_competent
            ]
          }.with_indifferent_access
        )
      end
    end

    context "some of the groups are empty" do
      let(:patient_session) { create(:patient_session, :consent_refused) }

      it "returns an empty array for all the empty groups" do
        result =
          subject.group_patient_sessions_by_state(
            [patient_session],
            section: :triage
          )

        expect(result).to eq(
          {
            needs_triage: [],
            triage_complete: [],
            no_triage_needed: [patient_session]
          }.with_indifferent_access
        )
      end
    end
  end

  describe "#count_patient_sessions" do
    let(:session) { create(:session) }
    let(:no_consent_patient_sessions) do
      create_list(:patient_session, 2, session:)
    end
    let(:refuser_patient_session) do
      create(:patient_session, :consent_refused, session:)
    end

    it "counts patient session groups" do
      patient_sessions = {
        no_consent: no_consent_patient_sessions,
        consent_given: [],
        consent_refused: [refuser_patient_session]
      }

      result = subject.count_patient_sessions(patient_sessions)

      expect(result).to eq(
        { no_consent: 2, consent_given: 0, consent_refused: 1 }
      )
    end
  end
end
