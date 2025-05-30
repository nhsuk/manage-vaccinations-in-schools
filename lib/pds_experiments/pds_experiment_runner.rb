# frozen_string_literal: true

module PDSExperiments
  class PDSExperimentRunner
    EXPERIMENTS = {
      "baseline" => "baseline",
      "fuzzy_no_history" => "fuzzy_no_history",
      "fuzzy_with_history" => "fuzzy_with_history",
      "wildcard_with_history" => "wildcard_with_history",
      "wildcard_no_history" => "wildcard_no_history",
      "wildcard_gender_with_history" => "wildcard_gender_with_history",
      "wildcard_gender_no_history" => "wildcard_gender_no_history",
      "exact_with_history" => "exact_with_history",
      "exact_no_history" => "exact_no_history",
      "cascading_search_1" => "cascading_search_1",
      "cascading_search_2" => "cascading_search_2",
      "cascading_search_3" => "cascading_search_3",
      "cascading_search_4" => "cascading_search_4",
      "baseline_with_gender" => "baseline_with_gender"
    }.freeze

    def initialize(
      patients,
      experiments: EXPERIMENTS.keys,
      priority: 10,
      queue: :experiments
    )
      @patients = patients
      @experiments = experiments
      @priority = priority
      @queue = queue
    end

    def run_experiment(experiment_name)
      strategy = EXPERIMENTS[experiment_name]
      raise "Unknown experiment: #{experiment_name}" unless strategy

      clear_experiment_results(experiment_name)

      patients.each_with_index do |patient, index|
        puts "Processing patient #{index + 1}/#{patients.count}: #{patient.id}"

        PDSExperiments::PDSExperimentJob.perform_now(
          patient,
          experiment_name,
          strategy
        )

        sleep(wait_between_jobs) if index < patients.count - 1
      end
    end

    def self.clear_all_results
      EXPERIMENTS.each_key do |experiment_name|
        new([]).send(:clear_experiment_results, experiment_name)
      end
      puts "All experiment results cleared"
    end

    private

    attr_reader :patients, :experiments, :priority, :queue

    def wait_between_jobs
      @wait_between_jobs ||= 0.5
    end

    def clear_experiment_results(experiment_name)
      counter_names = %w[
        total_attempts
        successful_lookups
        no_results
        too_many_matches_errors
        other_errors
        nhs_number_discrepancies
        family_name_discrepancies
        date_of_birth_discrepancies
        bad_requests
      ]

      counter_names.each do |counter_name|
        Rails.cache.delete("pds_experiment:#{experiment_name}:#{counter_name}")
      end
    end
  end
end
