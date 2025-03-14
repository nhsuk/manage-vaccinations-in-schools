# frozen_string_literal: true

class AppPatientSessionTriageComponent < ViewComponent::Base
  def initialize(patient_session, programme:, triage:)
    super

    @patient_session = patient_session
    @programme = programme
    @triage = triage
  end

  def render?
    !patient.triage_outcome.not_required?(programme)
  end

  private

  attr_reader :patient_session, :programme, :triage

  delegate :patient, :session, to: :patient_session

  def colour
    I18n.t(status, scope: %i[status triage colour])
  end

  def heading
    "#{programme.name}: #{I18n.t(status, scope: %i[status triage label])}"
  end

  def latest_triage
    @latest_triage ||= patient.triage_outcome.latest[programme]
  end

  def status
    patient.triage_outcome.status[programme]
  end
end
