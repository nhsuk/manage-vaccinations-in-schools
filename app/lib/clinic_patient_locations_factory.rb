# frozen_string_literal: true

class ClinicPatientLocationsFactory
  def initialize(school_session:, generic_clinic_session:)
    @school_session = school_session
    @generic_clinic_session = generic_clinic_session
  end

  def create_patient_locations!
    PatientLocation.import!(
      patient_locations_to_create,
      on_duplicate_key_ignore: true
    )

    if generic_clinic_session.scheduled_for_search_in_nhs_immunisations_api?
      patient_ids = patient_locations_to_create.map { it.patient.id }
      SearchVaccinationRecordsInNHSJob.perform_async(patient_ids.zip)
    end
  end

  def patient_locations_to_create
    patients_in_school.filter_map do |patient|
      if SendClinicInitialInvitationsJob.new.should_send_notification?(
           patient:,
           session: generic_clinic_session,
           programmes:,
           session_date:
         )
        PatientLocation.new(
          patient:,
          academic_year: generic_clinic_session.academic_year,
          location: generic_clinic_session.location
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
