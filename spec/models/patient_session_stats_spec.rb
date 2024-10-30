# frozen_string_literal: true

describe PatientSessionStats do
  describe "#to_h" do
    subject(:to_h) { described_class.new(session.patient_sessions).to_h }

    let(:programme) { create(:programme) }
    let(:session) { create(:session, programme:) }

    it "returns a hash of session stats" do
      expect(to_h).to eq(
        could_not_vaccinate: 0,
        needing_triage: 0,
        vaccinate: 0,
        vaccinated: 0,
        with_conflicting_consent: 0,
        with_consent_given: 0,
        with_consent_refused: 0,
        without_a_response: 0
      )
    end

    context "with patient sessions" do
      before do
        create(:patient_session, :consent_refused, programme:, session:) # consent refused
        create(:patient_session, :added_to_session, programme:, session:) # without a response
        create(
          :patient_session,
          :consent_given_triage_needed,
          programme:,
          session:
        ) # needing triage, consent given
        create(:patient_session, :triaged_kept_in_triage, programme:, session:) # needing triage, consent given
        create(
          :patient_session,
          :triaged_ready_to_vaccinate,
          programme:,
          session:
        ) # ready to vaccinate, consent given
        create(
          :patient_session,
          :consent_given_triage_not_needed,
          programme:,
          session:
        ) # ready to vaccinate, consent given

        create(:consent_form, :recorded, programme:, session:, consent_id: nil) # => unmatched response
        create(:consent_form, :draft, programme:, session:, consent_id: nil) # => still draft, should not be counted
      end

      it "returns a hash of session stats" do
        expect(to_h).to eq(
          could_not_vaccinate: 1,
          needing_triage: 2,
          vaccinate: 2,
          vaccinated: 0,
          with_conflicting_consent: 0,
          with_consent_given: 4,
          with_consent_refused: 1,
          without_a_response: 1
        )
      end
    end
  end
end
