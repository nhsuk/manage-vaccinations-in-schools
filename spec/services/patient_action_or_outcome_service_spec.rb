require "rails_helper"

describe PatientActionOrOutcomeService do
  describe "when consent is given, no triage needed and the vaccination is administered" do
    it "steps through the right actions and outcomes" do
      session = create(:session, patients_in_session: 1)
      patient = session.patients.first
      patient_session = patient.patient_sessions.find_by(session:)
      consent = nil
      triage = nil
      vaccination_record = nil

      # no consent yet
      outcome_or_action =
        PatientActionOrOutcomeService.call(
          consent:,
          triage:,
          vaccination_record:
        )
      expect(outcome_or_action).to eq({ action: :get_consent })

      # consent given
      consent =
        create(
          :consent_given,
          patient:,
          parent_relationship: :mother,
          campaign: session.campaign
        )
      outcome_or_action =
        PatientActionOrOutcomeService.call(
          consent:,
          triage:,
          vaccination_record:
        )
      expect(outcome_or_action).to eq({ action: :vaccinate })

      # vaccination administered
      vaccination_record =
        create(
          :vaccination_record,
          patient_session:,
          administered: true,
          site: :right_arm
        )
      outcome_or_action =
        PatientActionOrOutcomeService.call(
          consent:,
          triage:,
          vaccination_record:
        )
      expect(outcome_or_action).to eq({ outcome: :vaccinated })
    end
  end

  describe "when consent is refused" do
    it "steps through the right actions and outcomes" do
      session = create(:session, patients_in_session: 1)
      patient = session.patients.first
      triage = nil
      vaccination_record = nil

      # consent refused
      consent =
        create(
          :consent_refused,
          patient:,
          parent_relationship: :mother,
          campaign: session.campaign
        )
      outcome_or_action =
        PatientActionOrOutcomeService.call(
          consent:,
          triage:,
          vaccination_record:
        )
      expect(outcome_or_action).to eq({ action: :check_refusal })
    end
  end

  describe "when consent given by other, triage and follow-up needed, the vaccination is administered" do
    it "steps through the right actions and outcomes" do
      session = create(:session, patients_in_session: 1)
      patient = session.patients.first
      patient_session = patient.patient_sessions.find_by(session:)
      triage = nil
      vaccination_record = nil

      # consent given
      consent =
        create(
          :consent_given,
          patient:,
          parent_relationship: :other,
          campaign: session.campaign
        )
      outcome_or_action =
        PatientActionOrOutcomeService.call(
          consent:,
          triage:,
          vaccination_record:
        )
      expect(outcome_or_action).to eq({ action: :triage })

      # follow-up needed
      triage =
        create(
          :triage,
          patient:,
          campaign: session.campaign,
          status: :needs_follow_up
        )
      outcome_or_action =
        PatientActionOrOutcomeService.call(
          consent:,
          triage:,
          vaccination_record:
        )
      expect(outcome_or_action).to eq({ action: :follow_up })

      # triage done
      triage.update!(status: :ready_for_session)
      outcome_or_action =
        PatientActionOrOutcomeService.call(
          consent:,
          triage:,
          vaccination_record:
        )
      expect(outcome_or_action).to eq({ action: :vaccinate })

      # vaccination administered
      vaccination_record =
        create(
          :vaccination_record,
          patient_session:,
          administered: true,
          site: :left_arm
        )
      outcome_or_action =
        PatientActionOrOutcomeService.call(
          consent:,
          triage:,
          vaccination_record:
        )
      expect(outcome_or_action).to eq({ outcome: :vaccinated })
    end
  end

  describe "when consent given but patient triaged out" do
    it "steps through the right actions and outcomes" do
      session = create(:session, patients_in_session: 1)
      patient = session.patients.first
      triage = nil
      vaccination_record = nil

      # consent given
      consent =
        create(
          :consent_given,
          patient:,
          parent_relationship: :other,
          campaign: session.campaign
        )
      outcome_or_action =
        PatientActionOrOutcomeService.call(
          consent:,
          triage:,
          vaccination_record:
        )
      expect(outcome_or_action).to eq({ action: :triage })

      # triage decides not to vaccinate
      triage =
        create(
          :triage,
          patient:,
          campaign: session.campaign,
          status: :do_not_vaccinate
        )
      outcome_or_action =
        PatientActionOrOutcomeService.call(
          consent:,
          triage:,
          vaccination_record:
        )
      expect(outcome_or_action).to eq({ outcome: :do_not_vaccinate })
    end
  end

  describe "when consent given, but vaccination is not administered" do
    it "steps through the right actions and outcomes" do
      session = create(:session, patients_in_session: 1)
      patient = session.patients.first
      patient_session = patient.patient_sessions.find_by(session:)
      triage = nil
      vaccination_record = nil

      # consent given
      consent =
        create(
          :consent_given,
          patient:,
          parent_relationship: :mother,
          campaign: session.campaign
        )
      outcome_or_action =
        PatientActionOrOutcomeService.call(
          consent:,
          triage:,
          vaccination_record:
        )
      expect(outcome_or_action).to eq({ action: :vaccinate })

      # vaccination not administered
      vaccination_record =
        create(:vaccination_record, patient_session:, administered: false)
      outcome_or_action =
        PatientActionOrOutcomeService.call(
          consent:,
          triage:,
          vaccination_record:
        )
      expect(outcome_or_action).to eq({ outcome: :not_vaccinated })
    end
  end
end
