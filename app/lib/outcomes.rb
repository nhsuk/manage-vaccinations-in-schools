# frozen_string_literal: true

class Outcomes
  def initialize(
    patients: nil,
    patient: nil,
    patient_sessions: nil,
    patient_session: nil
  )
    if patient_session
      @patient_sessions = PatientSession.where(id: patient_session.id)
      @patients = Patient.where(id: patient_session.patient_id)
    elsif patient_sessions
      @patient_sessions = patient_sessions
      @patients = patient_sessions.select(:patient_id)
    elsif patient
      @patient_sessions = nil
      @patients = Patient.where(id: patient.id)
    else
      @patient_sessions = nil
      @patients = patients
    end
  end

  def programme
    @programme ||=
      ProgrammeOutcome.new(
        patients:,
        triage_outcome: triage,
        vaccinated_criteria:
      )
  end

  def register
    @register ||= RegisterOutcome.new(patient_sessions:)
  end

  def session
    @session ||=
      SessionOutcome.new(
        patient_sessions:,
        register_outcome: register,
        triage_outcome: triage
      )
  end

  def triage
    @triage ||= TriageOutcome.new(patients:, vaccinated_criteria:)
  end

  def vaccinated_criteria
    @vaccinated_criteria ||= VaccinatedCriteria.new(patients:)
  end

  private

  attr_reader :patients, :patient_sessions
end
