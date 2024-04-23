require "rails_helper"

describe PatientTabsConcern do
  subject { Class.new { include PatientTabsConcern }.new }

  describe "#group_patient_sessions_by_conditions" do
    let(:patient_session1) do
      create(:patient_session, :consent_given_triage_needed)
    end
    let(:patient_session2) { create(:patient_session, :consent_refused) }
    let(:patient_session3) { create(:patient_session, :consent_conflicting) }
    let(:patient_session4) { create(:patient_session) }

    it "groups patient sessions by conditions" do
      result =
        subject.group_patient_sessions_by_conditions(
          [
            patient_session1,
            patient_session2,
            patient_session3,
            patient_session4
          ],
          section: :consents
        )

      expect(result).to eq(
        {
          consent_given: [patient_session1],
          consent_refused: [patient_session2],
          conflicting_consent: [patient_session3],
          no_consent: [patient_session4]
        }.with_indifferent_access
      )
    end

    context "some of the groups are empty" do
      it "returns an empty array for all the empty groups" do
        result =
          subject.group_patient_sessions_by_conditions(
            [patient_session1],
            section: :consents
          )

        expect(result).to eq(
          {
            consent_given: [patient_session1],
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
      let(:patient_session1) do
        create(:patient_session, :consent_given_triage_needed)
      end
      let(:patient_session2) do
        create(:patient_session, :triaged_ready_to_vaccinate)
      end
      let(:patient_session3) do
        create(:patient_session, :consent_given_triage_not_needed)
      end

      it "groups patient sessions by triage states" do
        result =
          subject.group_patient_sessions_by_state(
            [patient_session1, patient_session2, patient_session3],
            section: :triage
          )

        expect(result).to eq(
          {
            needs_triage: [patient_session1],
            triage_complete: [patient_session2],
            no_triage_needed: [patient_session3]
          }.with_indifferent_access
        )
      end
    end

    context "vaccinations section" do
      let(:patient_session1) do
        create(:patient_session, :consent_given_triage_needed)
      end
      let(:patient_session2) { create(:patient_session, :vaccinated) }
      let(:patient_session3) { create(:patient_session, :delay_vaccination) }
      let(:patient_session4) { create(:patient_session, :consent_refused) }

      it "groups patient sessions by vaccination states" do
        result =
          subject.group_patient_sessions_by_state(
            [
              patient_session1,
              patient_session2,
              patient_session3,
              patient_session4
            ],
            section: :vaccinations
          )

        expect(result).to eq(
          {
            action_needed: [patient_session1],
            vaccinated: [patient_session2],
            vaccinate_later: [patient_session3],
            could_not_vaccinate: [patient_session4]
          }.with_indifferent_access
        )
      end
    end

    context "some of the groups are empty" do
      let(:patient_session) { create(:patient_session, :consent_refused) }

      it "returns an empty array for all the empty groups" do
        result =
          subject.group_patient_sessions_by_conditions(
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
    let(:patient_session1) { create(:patient_session) }
    let(:patient_session2) { create(:patient_session) }
    let(:patient_session3) { create(:patient_session, :consent_refused) }

    it "counts patient session groups" do
      patient_sessions = {
        no_consent: [patient_session1, patient_session2],
        consent_given: [],
        consent_refused: [patient_session3]
      }

      result = subject.count_patient_sessions(patient_sessions)

      expect(result).to eq(
        { no_consent: 2, consent_given: 0, consent_refused: 1 }
      )
    end
  end
end
