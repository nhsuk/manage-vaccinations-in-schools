# frozen_string_literal: true

class PatientNHSNumberLookupJob < ApplicationJob
  include NHSNumberLookupConcern

  queue_as :imports

  def perform(patient)
    return if patient.nhs_number.present?

    nhs_number = find_nhs_number(patient)
    return if nhs_number.nil?

    if (
         existing_patient =
           Patient.includes(
             :class_imports,
             :cohort_imports,
             :immunisation_imports,
             :patient_sessions
           ).find_by(nhs_number:)
       )
      merge_patients!(existing_patient, patient)
    else
      patient.update!(nhs_number:)
    end
  end

  def merge_patients!(patient_to_keep, patient_to_remove)
    ActiveRecord::Base.transaction do
      patient_to_remove.patient_sessions.each do |patient_session|
        if (
             existing_patient_session =
               patient_to_keep.patient_sessions.find_by(
                 session_id: patient_session.session_id
               )
           )
          patient_session.gillick_assessments.update_all(
            patient_session: existing_patient_session
          )
          patient_session.triages.update_all(
            patient_session: existing_patient_session
          )
          patient_session.vaccination_records.update_all(
            patient_session: existing_patient_session
          )
        else
          patient_session.update!(patient: patient_to_keep)
        end
      end

      PatientSession.where(patient: patient_to_remove).destroy_all

      patient_to_remove.class_imports.each do |import|
        unless patient_to_keep.class_imports.include?(import)
          patient_to_keep.class_imports << import
        end
      end

      patient_to_remove.cohort_imports.each do |import|
        unless patient_to_keep.cohort_imports.include?(import)
          patient_to_keep.cohort_imports << import
        end
      end

      patient_to_remove.immunisation_imports.each do |import|
        unless patient_to_keep.immunisation_imports.include?(import)
          patient_to_keep.immunisation_imports << import
        end
      end

      patient_to_remove.class_imports.clear
      patient_to_remove.cohort_imports.clear
      patient_to_remove.immunisation_imports.clear

      patient_to_remove.destroy!
    end
  end
end
