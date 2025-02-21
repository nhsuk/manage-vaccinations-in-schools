# frozen_string_literal: true

describe PatientSessionStats do
  describe "#to_h" do
    subject(:to_h) do
      described_class.new(
        session.patient_sessions.preload_for_status,
        programme:
      ).to_h
    end

    let(:programme) { create(:programme) }
    let(:session) { create(:session, programme:) }

    it "returns a hash of session stats" do
      expect(to_h).to eq(
        could_not_vaccinate: 0,
        needing_triage: 0,
        not_registered: 0,
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
        patient =
          create(
            :patient_session,
            :consent_refused,
            programme:,
            session:
          ).patient # consent refused
        create(:patient_session, :consent_refused, programme:, patient:) # duplicate is ignored

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

        create(:consent_form, :recorded, session:, consent_id: nil) # => unmatched response
        create(:consent_form, :draft, session:, consent_id: nil) # => still draft, should not be counted

        create(:patient_session, :consent_conflicting, programme:, session:) # conflicting consent

        gillick_patient =
          create(
            :patient_session,
            :consent_conflicting,
            programme:,
            session:
          ).patient
        create(:consent, :self_consent, patient: gillick_patient, programme:) # conflicting consent with gillick
      end

      it "returns a hash of session stats" do
        expect(to_h).to eq(
          could_not_vaccinate: 2,
          needing_triage: 2,
          not_registered: 8,
          vaccinate: 3,
          vaccinated: 0,
          with_conflicting_consent: 1,
          with_consent_given: 5,
          with_consent_refused: 1,
          without_a_response: 1
        )
      end
    end
  end
end
