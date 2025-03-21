# frozen_string_literal: true

class AppHealthQuestionsComponentPreview < ViewComponent::Preview
  include FactoryBot::Syntax::Methods

  def single_consent_triage_not_needed
    setup

    patient_session =
      create(:patient_session, :consent_given_triage_not_needed, session:)

    render AppHealthAnswersCardComponent.new(consents: patient_session.consents)
  end

  def single_consent_triage_needed
    setup

    patient_session =
      create(:patient_session, :consent_given_triage_needed, session:)

    render AppHealthAnswersCardComponent.new(consents: patient_session.consents)
  end

  def multiple_consents_no_triage_needed
    setup

    patient_session =
      create(:patient_session, :consent_given_triage_not_needed, session:)
    create(
      :consent,
      :given,
      :no_contraindications,
      patient: patient_session.patient,
      programme:
    )

    render AppHealthAnswersCardComponent.new(consents: patient_session.consents)
  end

  def multiple_consents_triage_needed
    setup

    patient_session =
      create(:patient_session, :consent_given_triage_needed, session:)
    patient_session.consents.first.update!(parent_relationship: :mother)

    dad_consent =
      create(
        :consent,
        :given,
        :health_question_notes,
        :from_dad,
        patient: patient_session.patient,
        programme:
      )

    dad_consent.health_answers.first.notes = "They fainted once"
    dad_consent.save!

    render AppHealthAnswersCardComponent.new(
             consents: patient_session.consents.reload
           )
  end

  private

  attr_reader :programme, :session

  def setup
    @programme =
      create(
        :programme,
        :hpv,
        organisation: Organisation.first || create(:organisation)
      )
    @session = create(:session, programmes: [@programme])
  end
end
