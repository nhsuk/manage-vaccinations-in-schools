# frozen_string_literal: true

class AppPatientSessionConsentComponent < ViewComponent::Base
  def initialize(patient_session, programme:)
    super

    @patient_session = patient_session
    @programme = programme
  end

  private

  attr_reader :patient_session, :programme

  delegate :patient, :session, to: :patient_session
  delegate :academic_year, to: :session

  def colour
    I18n.t(status, scope: %i[status consent colour])
  end

  def heading
    "#{programme.name}: #{I18n.t(status, scope: %i[status consent label])}"
  end

  def latest_consent_request
    @latest_consent_request ||=
      patient
        .consent_notifications
        .request
        .has_programme(programme)
        .joins(:session)
        .where(session: { academic_year: })
        .order(sent_at: :desc)
        .first
  end

  def consents
    @consents ||=
      patient
        .consents
        .where(academic_year:, programme:)
        .includes(:consent_form, :parent, :programme)
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
    consent_status.no_response? && patient.send_notifications? &&
      session.open_for_consent? && patient.parents.any?
  end

  def grouped_consents
    @grouped_consents ||=
      ConsentGrouper.call(consents, programme_id: programme.id, academic_year:)
  end

  def who_refused
    grouped_consents.find(&:response_refused?)&.who_responded
  end

  def show_health_answers?
    grouped_consents.any?(&:response_given?)
  end

  delegate :status, to: :consent_status
end
