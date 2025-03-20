# frozen_string_literal: true

class Patient::NextActivity
  def initialize(patient, outcomes:)
    @patient = patient
    @outcomes = outcomes
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

  attr_reader :patient, :outcomes

  def status_for_programme(programme)
    return REPORT if outcomes.programme.vaccinated?(patient, programme:)

    if patient.consent_given_and_safe_to_vaccinate?(outcomes:, programme:)
      return RECORD
    end

    return TRIAGE if outcomes.triage.required?(patient, programme:)

    if outcomes.consent.no_response?(patient, programme:) ||
         outcomes.consent.conflicts?(patient, programme:)
      return CONSENT
    end

    DO_NOT_RECORD
  end
end
