# frozen_string_literal: true

class ClinicPatientSessionsFactory
  def initialize(school_session:, generic_clinic_session:)
    @school_session = school_session
    @generic_clinic_session = generic_clinic_session
  end

  def create_patient_sessions!
    PatientSession.import!(
      patient_sessions_to_create,
      on_duplicate_key_ignore: true
    )
  end

  def patient_sessions_to_create
    patient_sessions_in_clinic =
      patient_sessions_in_school.map do |patient_session|
        PatientSession.includes(:session_notifications).find_or_initialize_by(
          patient: patient_session.patient,
          session: generic_clinic_session
        )
      end

    patient_sessions_in_clinic.select do |patient_session|
      SendClinicInitialInvitationsJob.new.should_send_notification?(
        patient_session:,
        programmes:,
        session_date:
      )
    end
  end

  private

  attr_reader :school_session, :generic_clinic_session

  def programmes
    @programmes ||= school_session.programmes.to_a
  end

  def session_date
    @session_date ||= generic_clinic_session.next_date(include_today: true)
  end

  def patient_sessions_in_school
    school_session.patient_sessions.includes(:patient)
  end
end
