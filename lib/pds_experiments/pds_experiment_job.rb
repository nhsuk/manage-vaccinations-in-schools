# frozen_string_literal: true

module PDSExperiments
  class PDSExperimentJob < ApplicationJob
    def perform(patient, experiment_name)
      increment_counter(experiment_name, "total_attempts")

      begin
        start_time = Time.zone.now
        pds_patient = execute_search_strategy(patient, experiment_name)
      rescue NHS::PDS::TooManyMatches
        increment_counter(experiment_name, "too_many_matches_errors")
        store_query_time(experiment_name, Time.zone.now - start_time)
        return
      rescue NHS::PDS::PatientNotFound
        increment_counter(experiment_name, "no_results")
        store_query_time(experiment_name, Time.zone.now - start_time)
        return
      rescue Faraday::BadRequestError
        increment_counter(experiment_name, "bad_requests")
        store_query_time(experiment_name, Time.zone.now - start_time)
        store_array_of_ids(experiment_name, "bad_request_ids", patient.id)
        return
      rescue StandardError => e
        increment_counter(experiment_name, "other_errors")
        puts "Error in PDSExperimentJob: #{e.message}"
        raise
      end

      store_query_time(experiment_name, Time.zone.now - start_time)

      if pds_patient
        increment_counter(experiment_name, "successful_lookups")

        store_nhs_number(experiment_name, patient, pds_patient)

        if patient.nhs_number.present? &&
             patient.nhs_number != pds_patient.nhs_number
          increment_counter(experiment_name, "nhs_number_discrepancies")
          store_array_of_ids(
            experiment_name,
            "nhs_number_discrepancy_ids",
            patient.id
          )
          store_nhs_discrepancy(experiment_name, patient, pds_patient)
        end

        if patient.family_name.to_s.casecmp(pds_patient.family_name.to_s) != 0
          increment_counter(experiment_name, "family_name_discrepancies")
          store_array_of_ids(
            experiment_name,
            "family_name_discrepancy_ids",
            patient.id
          )
          store_family_name_discrepancy(experiment_name, patient, pds_patient)
        end

        if patient.date_of_birth != pds_patient.date_of_birth
          increment_counter(experiment_name, "date_of_birth_discrepancies")
        end
      end
    end

    private

    def execute_search_strategy(patient, strategy)
      case strategy
      when "baseline"
        PDSExperiments::PDSExperimentSearcher.baseline_search(patient)
      when "fuzzy_no_history"
        PDSExperiments::PDSExperimentSearcher.fuzzy_search_without_history(
          patient
        )
      when "fuzzy_with_history"
        PDSExperiments::PDSExperimentSearcher.fuzzy_search_with_history(patient)
      when "wildcard_with_history"
        PDSExperiments::PDSExperimentSearcher.wildcard_search(
          patient,
          include_history: true
        )
      when "wildcard_no_history"
        PDSExperiments::PDSExperimentSearcher.wildcard_search(
          patient,
          include_history: false
        )
      when "wildcard_gender_with_history"
        PDSExperiments::PDSExperimentSearcher.wildcard_search(
          patient,
          include_gender: true,
          include_history: true
        )
      when "wildcard_gender_no_history"
        PDSExperiments::PDSExperimentSearcher.wildcard_search(
          patient,
          include_gender: true,
          include_history: false
        )
      when "exact_with_history"
        PDSExperiments::PDSExperimentSearcher.exact_search(
          patient,
          include_history: true
        )
      when "exact_no_history"
        PDSExperiments::PDSExperimentSearcher.exact_search(
          patient,
          include_history: false
        )
      when "cascading_search_1"
        PDSExperiments::PDSExperimentSearcher.cascading_search_1(
          patient,
          strategy
        )
      when "cascading_search_2"
        PDSExperiments::PDSExperimentSearcher.cascading_search_2(
          patient,
          strategy
        )
      when "cascading_search_3"
        PDSExperiments::PDSExperimentSearcher.cascading_search_3(
          patient,
          strategy
        )
      when "cascading_search_4"
        PDSExperiments::PDSExperimentSearcher.cascading_search_4(
          patient,
          strategy
        )
      when "cascading_search_5"
        PDSExperiments::PDSExperimentSearcher.cascading_search_5(
          patient,
          strategy
        )
      when "baseline_with_gender"
        PDSExperiments::PDSExperimentSearcher.baseline_search(
          patient,
          include_gender: true
        )
      else
        raise "Unknown search strategy: #{strategy}"
      end
    end

    def increment_counter(experiment_name, counter_name)
      cache_key = "pds_experiment:#{experiment_name}:#{counter_name}"
      Rails.cache.increment(cache_key, 1, expires_in: 7.days, initial: 0)
    end

    def store_query_time(experiment_name, elapsed_time)
      elapsed_ms = (elapsed_time * 1000).round(2)

      count_key = "pds_experiment:#{experiment_name}:count"
      total_key = "pds_experiment:#{experiment_name}:total_time"

      count =
        Rails.cache.increment(count_key, 1, expires_in: 7.days, initial: 0)
      total =
        Rails.cache.increment(
          total_key,
          elapsed_ms,
          expires_in: 7.days,
          initial: 0
        )

      avg = total.to_f / count
      Rails.cache.write(
        "pds_experiment:#{experiment_name}:avg_time",
        avg,
        expires_in: 7.days
      )
    end

    def store_family_name_discrepancy(experiment_name, patient, pds_patient)
      discrepancy_key =
        "pds_experiment:#{experiment_name}:family_name_discrepancy_patients"
      discrepancies = Rails.cache.read(discrepancy_key) || []

      discrepancies << {
        patient_id: patient.id,
        patient_family_name: patient.family_name,
        pds_family_name: pds_patient.family_name
      }

      Rails.cache.write(discrepancy_key, discrepancies, expires_in: 7.days)
    end

    def store_nhs_discrepancy(experiment_name, patient, pds_patient)
      discrepancy_key =
        "pds_experiment:#{experiment_name}:nhs_number_discrepancy_patients"
      discrepancies = Rails.cache.read(discrepancy_key) || []

      discrepancies << {
        patient_id: patient.id,
        patient_nhs: patient.nhs_number,
        pds_nhs: pds_patient.nhs_number
      }

      Rails.cache.write(discrepancy_key, discrepancies, expires_in: 7.days)
    end

    def store_nhs_number(experiment_name, patient, pds_patient)
      discrepancy_key = "pds_experiment:#{experiment_name}:nhs_numbers_returned"
      discrepancies = Rails.cache.read(discrepancy_key) || []

      discrepancies << {
        patient_id: patient.id,
        patient_nhs: patient.nhs_number || "",
        pds_nhs: pds_patient.nhs_number
      }

      Rails.cache.write(discrepancy_key, discrepancies, expires_in: 7.days)
    end

    def store_array_of_ids(experiment_name, array_name, patient_id)
      request_key = "pds_experiment:#{experiment_name}:#{array_name}"
      requests = Rails.cache.read(request_key) || []

      requests << patient_id unless requests.include?(patient_id)

      Rails.cache.write(request_key, requests, expires_in: 7.days)
    end
  end
end
