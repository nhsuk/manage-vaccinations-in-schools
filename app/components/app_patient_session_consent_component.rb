# frozen_string_literal: true

class AppPatientSessionConsentComponent < ViewComponent::Base
  def initialize(patient:, session:, programme:)
    @patient = patient
    @session = session
    @programme = programme
  end

  private

  attr_reader :patient, :session, :programme

  delegate :govuk_button_to, to: :helpers
  delegate :academic_year, to: :session

  def colour
    I18n.t(consent_status.status, scope: %i[status consent colour])
  end

  def heading
    status_with_suffix = consent_status.status

    if programme.has_multiple_vaccine_methods?
      vaccine_method =
        triage_status.vaccine_method.presence ||
          consent_status.vaccine_methods.first
      status_with_suffix += "_#{vaccine_method}" if vaccine_method
    end

    status_with_suffix += "_without_gelatine" if consent_status.without_gelatine

    "#{programme.name}: #{I18n.t(status_with_suffix, scope: %i[status consent label])}"
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

  def triage_status
    @triage_status ||= patient.triage_status(programme:, academic_year:)
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
      ConsentGrouper.call(consents, programme_id: programme.id, academic_year:)
  end

  def who_refused
    grouped_consents.find(&:response_refused?)&.who_responded
  end

  def show_health_answers?
    grouped_consents.any?(&:response_given?)
  end
end
