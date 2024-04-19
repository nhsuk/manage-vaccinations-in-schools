require "rails_helper"

describe PatientTabsConcern do
  subject { Class.new { include PatientTabsConcern }.new }

  describe "#group_patient_sessions_by_conditions" do
    let(:patient_session1) { create(:patient_session) }
    let(:patient_session2) do
      create(:patient_session, :consent_given_triage_needed)
    end
    let(:patient_session3) { create(:patient_session, :consent_refused) }

    it "groups patient sessions by conditions" do
      tab_conditions = {
        no_consent: %i[no_consent?],
        consent_given: %i[consent_given?],
        consent_refused: %i[consent_refused?]
      }

      result =
        subject.group_patient_sessions_by_conditions(
          [patient_session1, patient_session2, patient_session3],
          tab_conditions
        )

      expect(result).to eq(
        {
          no_consent: [patient_session1],
          consent_given: [patient_session2],
          consent_refused: [patient_session3]
        }
      )
    end

    context "one of the groups is empty" do
      it "returns an empty array for the empty group" do
        tab_conditions = {
          no_consent: %i[no_consent?],
          consent_given: %i[consent_given?],
          consent_refused: %i[consent_refused?]
        }

        result =
          subject.group_patient_sessions_by_conditions(
            [patient_session1],
            tab_conditions
          )

        expect(result).to eq(
          {
            no_consent: [patient_session1],
            consent_given: [],
            consent_refused: []
          }
        )
      end
    end
  end

  describe "#group_patient_sessions_by_states" do
    let(:patient_session1) { create(:patient_session) }
    let(:patient_session2) do
      create(:patient_session, :consent_given_triage_needed)
    end
    let(:patient_session3) do
      create(:patient_session, :consent_given_triage_not_needed)
    end
    let(:patient_sessions) do
      [patient_session1, patient_session2, patient_session3]
    end

    it "groups patient sessions by states" do
      tab_states = {
        needs_triage: %w[added_to_session],
        triage_complete: %w[consent_given_triage_needed],
        no_triage_needed: %w[consent_given_triage_not_needed]
      }

      result =
        subject.group_patient_sessions_by_state(patient_sessions, tab_states)

      expect(result).to eq(
        {
          needs_triage: [patient_session1],
          triage_complete: [patient_session2],
          no_triage_needed: [patient_session3]
        }
      )
    end

    context "one of the groups is empty" do
      it "returns an empty array for the empty group" do
        tab_states = {
          needs_triage: %w[added_to_session],
          triage_complete: %w[consent_given_triage_needed],
          no_triage_needed: %w[consent_given_triage_not_needed]
        }

        result =
          subject.group_patient_sessions_by_state(
            [patient_session1],
            tab_states
          )

        expect(result).to eq(
          {
            needs_triage: [patient_session1],
            triage_complete: [],
            no_triage_needed: []
          }
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
