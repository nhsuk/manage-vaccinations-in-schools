# frozen_string_literal: true

class AppConsentComponentPreview < ViewComponent::Preview
  include FactoryBot::Syntax::Methods

  def consent_refused_without_notes
    setup

    patient_session = create(:patient_session, :consent_refused, session:)

    render AppConsentComponent.new(patient_session:, route: "triage")
  end

  def consent_refused_with_notes
    setup

    patient_session =
      create(:patient_session, :consent_refused_with_notes, session:)

    render AppConsentComponent.new(patient_session:, route: "triage")
  end

  def consent_given
    setup

    patient_session =
      create(:patient_session, :consent_given_triage_not_needed, session:)
    render AppConsentComponent.new(patient_session:, route: "triage")
  end

  def two_refusals_from_the_same_parent
    setup

    patient_session = create(:patient_session, :consent_refused, session:)
    create(
      :consent,
      :refused,
      patient_session:,
      parent_relationship: patient_session.consents.first.parent_relationship,
      parent_name: patient_session.consents.first.parent_name
    )

    render AppConsentComponent.new(patient_session:, route: "triage")
  end

  def conflicting_consents_from_different_parents
    setup

    patient_session =
      create(:patient_session, :consent_given_triage_not_needed, session:)
    create(:consent, :refused, :from_mum, patient_session:)

    render AppConsentComponent.new(patient_session:, route: "triage")
  end

  private

  attr_reader :programme, :session

  def setup
    @programme = create(:programme, :hpv, team: Team.first || create(:team))
    @session = create(:session, programme:)
  end
end
