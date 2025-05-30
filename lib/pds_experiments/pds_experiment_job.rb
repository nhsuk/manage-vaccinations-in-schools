# frozen_string_literal: true

module PDSExperiments
  class PDSExperimentJob < ApplicationJob
    def perform(patient, experiment_name, search_strategy)
      increment_counter(experiment_name, "total_attempts")

      begin
        pds_patient = execute_search_strategy(patient, search_strategy)
      rescue NHS::PDS::TooManyMatches
        increment_counter(experiment_name, "too_many_matches_errors")
        return
      rescue NHS::PDS::PatientNotFound
        increment_counter(experiment_name, "no_results")
        return
      rescue Faraday::BadRequestError
        increment_counter(experiment_name, "bad_requests")
        return
      rescue StandardError => e
        increment_counter(experiment_name, "other_errors")
        puts "PDS Experiment error for #{experiment_name}: #{e.message}"
        return
      end

      if pds_patient
        increment_counter(experiment_name, "successful_lookups")

        if patient.nhs_number.present? &&
             patient.nhs_number != pds_patient.nhs_number
          increment_counter(experiment_name, "nhs_number_discrepancies")
        end

        if patient.family_name.to_s != pds_patient.family_name.to_s
          increment_counter(experiment_name, "family_name_discrepancies")
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
        PDSExperiments::PDSExperimentSearcher.cascading_search_1(patient)
      when "cascading_search_2"
        PDSExperiments::PDSExperimentSearcher.cascading_search_2(patient)
      when "cascading_search_3"
        PDSExperiments::PDSExperimentSearcher.cascading_search_3(patient)
      when "cascading_search_4"
        PDSExperiments::PDSExperimentSearcher.cascading_search_4(patient)
      when "baseline_with_gender"
        PDSExperiments::PDSExperimentSearcher.baseline_search(patient, include_gender: true)
      else
        raise "Unknown search strategy: #{strategy}"
      end
    end

    def increment_counter(experiment_name, counter_name)
      cache_key = "pds_experiment:#{experiment_name}:#{counter_name}"
      Rails.cache.increment(cache_key, 1, expires_in: 7.days, initial: 0)
    end
  end
end
