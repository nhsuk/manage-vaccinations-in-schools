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
           :consent_outcome,
           :triage_outcome,
           :programme_outcome,
           to: :patient

  def status_for_programme(programme)
    return REPORT if programme_outcome.vaccinated?(programme)

    return RECORD if consent_given_and_safe_to_vaccinate?(programme:)

    return TRIAGE if triage_outcome.required?(programme)

    if consent_outcome.no_response?(programme) ||
         consent_outcome.conflicts?(programme)
      return CONSENT
    end

    DO_NOT_RECORD
  end
end
