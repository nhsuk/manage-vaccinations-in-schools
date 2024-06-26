# frozen_string_literal: true

class AppConsentComponentPreview < ViewComponent::Preview
  def consent_refused_without_notes
    setup

    patient_session =
      FactoryBot.create(:patient_session, :consent_refused, session:)

    render AppConsentComponent.new(patient_session:, route: "triage")
  end

  def consent_refused_with_notes
    setup

    patient_session =
      FactoryBot.create(:patient_session, :consent_refused_with_notes, session:)

    render AppConsentComponent.new(patient_session:, route: "triage")
  end

  def consent_given
    setup

    patient_session =
      FactoryBot.create(
        :patient_session,
        :consent_given_triage_not_needed,
        session:
      )
    render AppConsentComponent.new(patient_session:, route: "triage")
  end

  def two_refusals_from_the_same_parent
    setup

    patient_session =
      FactoryBot.create(:patient_session, :consent_refused, session:)
    FactoryBot.create(
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
      FactoryBot.create(
        :patient_session,
        :consent_given_triage_not_needed,
        session:
      )
    FactoryBot.create(:consent, :refused, :from_mum, patient_session:)

    render AppConsentComponent.new(patient_session:, route: "triage")
  end

  private

  attr_reader :campaign, :session

  def setup
    @campaign =
      FactoryBot.create(
        :campaign,
        :hpv,
        team: Team.first || FactoryBot.create(:team)
      )
    @session = FactoryBot.create(:session, patients_in_session: 0, campaign:)
  end
end
