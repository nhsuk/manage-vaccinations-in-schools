# frozen_string_literal: true

class ClinicPatientLocationsFactory
  def initialize(school_session:)
    @school_session = school_session
  end

  def create_patient_locations!
    ActiveRecord::Base.transaction do
      PatientLocation.import!(
        patient_locations_to_create,
        on_duplicate_key_ignore: true
      )

      PatientTeamUpdater.call(patient_scope: patients_in_school, team:)
    end
  end

  def patient_locations_to_create
    patients_in_school
      .select { should_add_to_clinic?(it) }
      .map do |patient|
        PatientLocation.new(
          patient:,
          academic_year:,
          location: generic_clinic_location
        )
      end
  end

  private

  attr_reader :school_session

  delegate :academic_year, :team, to: :school_session

  def patients_in_school = school_session.patients.includes_statuses

  def generic_clinic_location
    @generic_clinic_location ||= team.generic_clinic
  end

  def should_add_to_clinic?(patient)
    return false unless patient.send_notifications?(team:)

    eligible_programmes =
      school_session
        .programmes_for(patient:)
        .select do
          programme_status = patient.programme_status(it, academic_year:)
          !programme_status.vaccinated? && !programme_status.consent_refused?
        end

    return false if eligible_programmes.empty?

    !patient.invited_to_clinic?(eligible_programmes, team:, academic_year:)
  end
end
