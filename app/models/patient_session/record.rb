# frozen_string_literal: true

class PatientSession::Record
  def initialize(patient_session)
    @patient_session = patient_session
  end

  STATUSES = [
    VACCINATED = :administered,
    ALREADY_HAD = :already_had,
    HAD_CONTRAINDICATIONS = :contraindications,
    REFUSED = :refused,
    ABSENT_FROM_SCHOOL = :absent_from_school,
    ABSENT_FROM_SESSION = :absent_from_session,
    UNWELL = :not_well,
    NONE = :none
  ].freeze

  def status
    @status ||= programmes.index_with { programme_status(it) }
  end

  def all(programme:)
    patient.vaccination_records.select do
      it.programme_id == programme.id && it.session_id == session.id
    end
  end

  def latest(programme:)
    latest_by_programme[programme.id]
  end

  private

  attr_reader :patient_session

  delegate :patient, :session, :programmes, to: :patient_session

  def programme_status(programme)
    latest(programme:)&.outcome&.to_sym || NONE
  end

  def latest_by_programme
    @latest_by_programme ||=
      patient
        .vaccination_records
        .select { it.session_id == session.id }
        .reject(&:discarded?)
        .group_by(&:programme_id)
        .transform_values { it.max_by(&:created_at) }
  end
end
