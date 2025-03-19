# frozen_string_literal: true

class Outcomes
  def initialize(patients: nil, patient_sessions: nil, patient_session: nil)
    if patient_session
      @patients = Patient.where(id: patient_session.patient_id)
      @patient_sessions = PatientSession.where(id: patient_session.id)
    elsif patient_sessions
      @patient_sessions = patient_sessions
      @patients = patient_sessions.select(:patient_id)
    else
      @patient_sessions = nil
      @patients = patients
    end
  end

  def session
    @session ||= SessionOutcome.new(patient_sessions:)
  end

  private

  attr_reader :patients, :patient_sessions
end
