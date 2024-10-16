# frozen_string_literal: true

class PDSLookupJob < ApplicationJob
  include GoodJob::ActiveJobExtensions::Concurrency

  queue_as :pds

  # NHS API imposes a limit of 5 requests per second
  good_job_control_concurrency_with perform_limit: 5,
                                    perform_throttle: [5, 1.second],
                                    key: -> { queue_name }

  # Because the NHS API imposes a limit of 5 requests per second, we're almost
  # certain to hit throttling and the default exponential backoff strategy
  # appears to trigger more race conditions in the job performing code, meaning
  # there’s more instances where more than 5 requests are attempted.
  retry_on GoodJob::ActiveJobExtensions::Concurrency::ConcurrencyExceededError,
           attempts: :unlimited,
           wait: ->(_) { rand(0.5..5) }

  def perform(patient)
    return if patient.nhs_number.present?

    query = {
      "family" => patient.family_name,
      "given" => patient.given_name,
      "birthdate" => "eq#{patient.date_of_birth}",
      "address-postalcode" => patient.address_postcode,
      "_history" => true # look up previous names and addresses,
    }.compact_blank

    response = NHS::PDS.search_patients(query)
    results = response.body

    return if results["total"].zero?

    entry = results["entry"].first
    nhs_number = entry["resource"]["id"]

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
