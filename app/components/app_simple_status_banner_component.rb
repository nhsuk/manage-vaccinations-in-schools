# frozen_string_literal: true

class AppSimpleStatusBannerComponent < ViewComponent::Base
  def initialize(patient_session:, programme:)
    super

    @patient_session = patient_session
    @programme = programme
  end

  def call
    render AppCardComponent.new(colour:) do |card|
      card.with_heading { heading }
      tag.p(description)
    end
  end

  private

  attr_reader :patient_session, :programme

  delegate :patient, :session, to: :patient_session

  def status
    @status ||= patient_session.status(programme:)
  end

  def colour
    I18n.t("patient_session_statuses.#{status}.colour")
  end

  def heading
    I18n.t("patient_session_statuses.#{status}.banner_title")
  end

  def description
    options = {
      default: "",
      full_name: patient.full_name,
      nurse:,
      who_refused:,
      programme_name: programme.name
    }

    triage_status =
      patient
        .triage_statuses
        .includes(:consents, :programme, :vaccination_records)
        .find_by(programme:)

    if triage_status&.required?
      reasons = [
        if triage_status.consent_requires_triage?
          I18n.t(
            :consent_needs_triage,
            scope: %i[
              patient_session_statuses
              consent_given_triage_needed
              banner_explanation
            ],
            **options
          )
        end,
        if triage_status.vaccination_history_requires_triage?
          I18n.t(
            :vaccination_partially_administered,
            scope: %i[
              patient_session_statuses
              consent_given_triage_needed
              banner_explanation
            ],
            **options
          )
        end
      ].compact

      safe_join(reasons, tag.br)
    else
      I18n.t("patient_session_statuses.#{status}.banner_explanation", **options)
    end
  end

  def who_refused
    consents =
      patient.consents.where(programme:).not_invalidated.includes(:parent)

    ConsentGrouper
      .call(consents, programme:)
      .find(&:response_refused?)
      &.who_responded
  end

  def nurse
    (
      patient.triages.includes(:performed_by).where(programme:) +
        patient
          .vaccination_records
          .includes(:performed_by_user)
          .where(programme:)
    ).max_by(&:updated_at)&.performed_by&.full_name
  end
end
