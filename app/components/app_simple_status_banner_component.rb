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

      safe_join(
        [
          tag.p(description),
          if (link = update_triage_outcome_link)
            tag.p(link)
          end
        ]
      )
    end
  end

  private

  attr_reader :patient_session, :programme

  delegate :patient, :session, to: :patient_session

  def status
    @status ||= @patient_session.status(programme:)
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

    if patient_session.consent_given_triage_needed?(programme:)
      reasons = [
        if patient_session.consent_needs_triage?(programme:)
          I18n.t(
            "patient_session_statuses.#{status}.banner_explanation.consent_needs_triage",
            **options
          )
        end,
        if patient_session.vaccination_partially_administered?(programme:)
          I18n.t(
            "patient_session_statuses.#{status}.banner_explanation.vaccination_partially_administered",
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
    patient_session
      .latest_consents(programme:)
      .select(&:response_refused?)
      .map(&:who_responded)
      .last
  end

  def nurse
    (
      patient_session.triages(programme:) +
        patient_session.vaccination_records(programme:)
    ).max_by(&:updated_at)&.performed_by&.full_name
  end

  def update_triage_outcome_link
    unless status.in?(
             %w[
               delay_vaccination
               triaged_ready_to_vaccinate
               triaged_do_not_vaccinate
             ]
           ) && helpers.policy(Triage).edit?
      return
    end

    link_to(
      "Update triage outcome",
      new_session_patient_programme_triages_path(session, patient, programme)
    )
  end
end
