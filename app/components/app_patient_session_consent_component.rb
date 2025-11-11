# frozen_string_literal: true

class AppPatientSessionConsentComponent < AppPatientSessionSectionComponent
  private

  delegate :govuk_button_to, to: :helpers

  def resolved_status
    @resolved_status ||= patient_status_resolver.consent
  end

  def latest_consent_request
    @latest_consent_request ||=
      patient
        .consent_notifications
        .request
        .has_all_programmes_of([programme])
        .joins(:session)
        .where(session: { academic_year: })
        .order(sent_at: :desc)
        .first
  end

  def consents
    @consents ||=
      patient
        .consents
        .where_programme(programme)
        .where(academic_year:)
        .includes(:consent_form, :parent)
        .order(created_at: :desc)
  end

  def consent_status
    @consent_status ||= patient.consent_status(programme:, academic_year:)
  end

  def vaccination_status
    @vaccination_status ||=
      patient.vaccination_status(programme:, academic_year:)
  end

  def can_send_consent_request?
    consent_status.no_response? &&
      patient.send_notifications?(team: @session.team) &&
      session.open_for_consent? && patient.parents.any?
  end

  def grouped_consents
    @grouped_consents ||=
      ConsentGrouper.call(
        consents,
        programme_type: programme.type,
        academic_year:
      )
  end

  def who_refused
    grouped_consents.find(&:response_refused?)&.who_responded
  end

  def show_health_answers?
    grouped_consents.any?(&:response_given?)
  end
end
