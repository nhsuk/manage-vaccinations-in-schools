# frozen_string_literal: true

class PatientSession::Consent
  def initialize(patient_session)
    @patient_session = patient_session
  end

  STATUSES = [
    GIVEN = :given,
    REFUSED = :refused,
    CONFLICTS = :conflicts,
    NONE = :none
  ].freeze

  def status
    @status ||= programmes.index_with { programme_status(it) }
  end

  def all(programme:)
    patient.consents.select { it.programme_id == programme.id }
  end

  def latest(programme:)
    latest_consents_by_programme.fetch(programme.id, [])
  end

  private

  attr_reader :patient_session

  delegate :patient, :programmes, to: :patient_session

  def programme_status(programme)
    if consent_given?(programme:)
      GIVEN
    elsif consent_refused?(programme:)
      REFUSED
    elsif consent_conflicts?(programme:)
      CONFLICTS
    else
      NONE
    end
  end

  def consent_given?(programme:)
    if self_consents(programme:).any?
      self_consents(programme:).all?(&:response_given?)
    else
      latest(programme:).any? && latest(programme:).all?(&:response_given?)
    end
  end

  def consent_refused?(programme:)
    latest(programme:).any? && latest(programme:).all?(&:response_refused?)
  end

  def consent_conflicts?(programme:)
    if self_consents(programme:).any?
      self_consents(programme:).any?(&:response_refused?) &&
        self_consents(programme:).any?(&:response_given?)
    else
      latest(programme:).any?(&:response_refused?) &&
        latest(programme:).any?(&:response_given?)
    end
  end

  def self_consents(programme:)
    latest(programme:).select(&:via_self_consent?)
  end

  def latest_consents_by_programme
    @latest_consents_by_programme ||=
      patient
        .consents
        .reject(&:invalidated?)
        .select { it.response_given? || it.response_refused? }
        .group_by(&:programme_id)
        .transform_values do |consents|
          consents.group_by(&:name).map { it.second.max_by(&:created_at) }
        end
  end
end
