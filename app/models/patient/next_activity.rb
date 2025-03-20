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

  delegate :consent_given_and_safe_to_vaccinate?, :consent_outcome, to: :patient

  def status_for_programme(programme)
    return REPORT if outcomes.programme.vaccinated?(patient, programme:)

    return RECORD if consent_given_and_safe_to_vaccinate?(outcomes:, programme:)

    return TRIAGE if outcomes.triage.required?(patient, programme:)

    if consent_outcome.no_response?(programme) ||
         consent_outcome.conflicts?(programme)
      return CONSENT
    end

    DO_NOT_RECORD
  end
end
