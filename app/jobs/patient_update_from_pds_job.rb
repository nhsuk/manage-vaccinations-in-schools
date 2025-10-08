# frozen_string_literal: true

class PatientUpdateFromPDSJob < ApplicationJob
  include PDSAPIThrottlingConcern

  queue_as :pds

  def perform(patient, search_results = [])
    raise MissingNHSNumber if patient.nhs_number.nil? && search_results.empty?

    unique_nhs_number =
      (
        if search_results.present?
          get_unique_nhs_number(search_results)
        else
          patient.nhs_number
        end
      )
    return unless unique_nhs_number

    pds_patient = PDS::Patient.find(unique_nhs_number)

    if pds_patient.nhs_number != patient.nhs_number
      if (
           existing_patient =
             Patient.find_by(nhs_number: pds_patient.nhs_number)
         )
        PatientMerger.call(to_keep: existing_patient, to_destroy: patient)
        existing_patient.update_from_pds!(pds_patient)

        if search_results.present?
          import_search_results(existing_patient, search_results)
        end
      else
        patient.nhs_number = pds_patient.nhs_number
        patient.update_from_pds!(pds_patient)

        if search_results.present?
          import_search_results(patient, search_results)
        end
      end
    else
      patient.update_from_pds!(pds_patient)
    end
  rescue NHS::PDS::PatientNotFound
    patient.update!(nhs_number: nil)
    if Flipper.enabled?(:pds_cascading_search)
      PDSCascadingSearchJob.perform_later(
        searchable_id: patient.id,
        searchable_type: patient.class.name
      )
    else
      PatientNHSNumberLookupJob.perform_later(patient)
    end
  rescue NHS::PDS::InvalidatedResource, NHS::PDS::InvalidNHSNumber
    patient.invalidate!
    if Flipper.enabled?(:pds_cascading_search)
      PDSCascadingSearchJob.perform_later(
        searchable_id: patient.id,
        searchable_type: patient.class.name
      )
    else
      PatientNHSNumberLookupJob.perform_later(patient)
    end
  end

  class MissingNHSNumber < StandardError
  end

  private

  def import_search_results(patient, search_results)
    search_results.each do |result|
      PDSSearchResult.create!(
        patient_id: patient.id,
        step: result[:step],
        result: result[:result],
        nhs_number: result[:nhs_number],
        created_at: result[:created_at]
      )
    end
  end

  def get_unique_nhs_number(search_results)
    nhs_numbers = search_results.pluck("nhs_number").compact.uniq
    nhs_numbers.count == 1 ? nhs_numbers.first : nil
  end
end
