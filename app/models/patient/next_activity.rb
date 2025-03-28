# frozen_string_literal: true

class Patient::NextActivity
  def initialize(patient)
    @patient = patient
  end

  STATUSES = [
    DO_NOT_RECORD = :do_not_record,
    CONSENT = :consent,
    TRIAGE = :triage,
    REPORT = :report,
    RECORD = :record
  ].freeze

  def status
    @status ||=
      Hash.new do |hash, programme|
        hash[programme] = status_for_programme(programme)
      end
  end

  private

  attr_reader :patient

  delegate :consent_given_and_safe_to_vaccinate?,
           :programme_outcome,
           to: :patient

  def status_for_programme(programme)
    return REPORT if programme_outcome.vaccinated?(programme)

    return RECORD if consent_given_and_safe_to_vaccinate?(programme:)

    return TRIAGE if patient.triage_status(programme:).required?

    consent_status = patient.consent_status(programme:)

    return CONSENT if consent_status.no_response? || consent_status.conflicts?

    DO_NOT_RECORD
  end
end
