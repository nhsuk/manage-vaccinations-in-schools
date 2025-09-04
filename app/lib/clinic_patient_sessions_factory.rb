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
    patients_in_school.filter_map do |patient|
      if SendClinicInitialInvitationsJob.new.should_send_notification?(
           patient:,
           session: generic_clinic_session,
           programmes:,
           session_date:
         )
        PatientSession.includes(:session_notifications).find_or_initialize_by(
          patient:,
          session: generic_clinic_session
        )
      end
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

  def patients_in_school
    school_session.patients.includes(:consent_statuses, :vaccination_statuses)
  end
end
