# frozen_string_literal: true

module PDSExperiments
  class PDSExperimentAnalyzer
    COUNTER_NAMES = %w[
      total_attempts
      successful_lookups
      no_results
      too_many_matches_errors
      other_errors
      nhs_number_discrepancies
      family_name_discrepancies
      date_of_birth_discrepancies
      bad_requests
    ].freeze

    def initialize(experiment_name)
      @experiment_name = experiment_name
    end

    def analyze
      counters = fetch_counters
      total = counters["total_attempts"] || 0

      return { error: "No data found for #{experiment_name}" } if total.zero?

      successful = counters["successful_lookups"] || 0
      coverage_percentage = (successful.to_f / total * 100).round(2)

      {
        experiment_name: experiment_name,
        total_attempts: total,
        successful_lookups: successful,
        coverage_percentage: coverage_percentage,
        no_results: counters["no_results"] || 0,
        too_many_matches_errors: counters["too_many_matches_errors"] || 0,
        other_errors: counters["other_errors"] || 0,
        nhs_number_discrepancies: counters["nhs_number_discrepancies"] || 0,
        family_name_discrepancies: counters["family_name_discrepancies"] || 0,
        date_of_birth_discrepancies:
          counters["date_of_birth_discrepancies"] || 0,
        bad_requests: counters["bad_requests"] || 0,
        summary:
          generate_summary(counters, total, successful, coverage_percentage)
      }
    end

    def self.analyze_all_experiments
      PDSExperiments::PDSExperimentRunner::EXPERIMENTS
        .keys
        .map { |experiment_name| new(experiment_name).analyze }
    end

    def self.compare_experiments
      all_results = analyze_all_experiments.reject { |r| r[:error] }

      puts "=== PDS Experiment Comparison ==="
      puts sprintf(
             "%-30s %10s %10s %15s %10s",
             "Experiment",
             "Total",
             "Success",
             "Coverage %",
             "NHS Disc."
           )
      puts "-" * 80

      all_results.each do |result|
        puts sprintf(
               "%-30s %10d %10d %14.2f%% %10d",
               result[:experiment_name],
               result[:total_attempts],
               result[:successful_lookups],
               result[:coverage_percentage],
               result[:nhs_number_discrepancies]
             )
      end

      puts "=== End Comparison ==="

      all_results
    end

    private

    attr_reader :experiment_name

    def fetch_counters
      counters = {}
      COUNTER_NAMES.each do |counter_name|
        cache_key = "pds_experiment:#{experiment_name}:#{counter_name}"
        counters[counter_name] = Rails.cache.read(cache_key) || 0
      end
      counters
    end

    def generate_summary(counters, total, successful, coverage_percentage)
      summary = []
      summary << "Coverage: #{coverage_percentage}% (#{successful}/#{total})"
      summary << "No results: #{counters["no_results"]}"
      if counters["too_many_matches_errors"].positive?
        summary << "Too many matches: #{counters["too_many_matches_errors"]}"
      end
      if counters["other_errors"].positive?
        summary << "Other errors: #{counters["other_errors"]}"
      end
      if counters["nhs_number_discrepancies"].positive?
        summary << "NHS number discrepancies: #{counters["nhs_number_discrepancies"]}"
      end

      summary.join(" | ")
    end
  end
end
