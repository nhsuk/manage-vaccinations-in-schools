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
      nhs_number_discrepancy_ids
      nhs_number_discrepancy_patients
      family_name_discrepancies
      date_of_birth_discrepancies
      bad_requests
      family_name_discrepancy_ids
      family_name_discrepancy_patients
      avg_time
      total_time
      count
      bad_request_ids
    ].freeze

    CASCADING_STEP_NAMES = %w[
      baseline
      wildcard_surname
      wildcard_given_name
      wildcard_postcode
      fuzzy_with_history
      fuzzy_without_history
      non_fuzzy_without_history
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

      result = {
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
        total_time: counters["total_time"] || 0,
        avg_time: counters["avg_time"] || 0,
        count: counters["count"] || 0,
        bad_request_ids: counters["bad_request_ids"] || [],
        family_name_discrepancy_ids:
          counters["family_name_discrepancy_ids"] || [],
        nhs_number_discrepancy_ids:
          counters["nhs_number_discrepancy_ids"] || [],
        nhs_number_discrepancy_patients:
          counters["nhs_number_discrepancy_patients"] || [],
        family_name_discrepancy_patients:
          counters["family_name_discrepancy_patients"] || [],
        summary:
          generate_summary(counters, total, successful, coverage_percentage)
      }

      if cascading_search?
        result[:step_analysis] = analyze_cascading_steps(counters, total)
      end

      result
    end

    def analyze_cascading_steps(counters = nil, total = nil)
      counters ||= fetch_counters
      total ||= counters["total_attempts"] || 0

      return {} if total.zero?

      step_stats = {}

      CASCADING_STEP_NAMES.each do |step_name|
        step_data = {}

        %w[reached successful].each do |metric|
          key = "step_#{step_name}_#{metric}"
          step_data[metric] = counters[key] || 0
        end

        failure_metrics =
          counters.keys.select do |k|
            k.start_with?("step_#{step_name}_failed_with_")
          end
        failure_metrics.each do |metric|
          failure_type = metric.gsub("step_#{step_name}_failed_with_", "")
          step_data["failed_with_#{failure_type}"] = counters[metric] || 0
        end

        step_data["success_rate"] = if step_data["reached"].positive?
          (step_data["successful"].to_f / step_data["reached"] * 100).round(2)
        else
          0
        end

        step_data["reach_rate"] = (
          step_data["reached"].to_f / total * 100
        ).round(2)

        step_stats[step_name] = step_data if step_data["reached"].positive?
      end

      step_stats["exhausted_all_steps"] = {
        "total" => counters["exhausted_all_steps_total"] || 0,
        "percentage" =>
          (
            (counters["exhausted_all_steps_total"] || 0).to_f / total * 100
          ).round(2)
      }

      step_stats
    end

    def print_cascading_analysis
      return unless cascading_search?

      analysis = analyze
      step_analysis = analysis[:step_analysis]
      total = analysis[:total_attempts]

      puts "\n=== Cascading Search Analysis for #{experiment_name} ==="
      puts "Total Attempts: #{total}"
      puts "Overall Success Rate: #{analysis[:coverage_percentage]}%"
      puts

      puts "Step Performance:"
      puts sprintf(
             "%-20s %10s %10s %12s %12s",
             "Step",
             "Reached",
             "Success",
             "Success%",
             "Reach%"
           )
      puts "-" * 66

      CASCADING_STEP_NAMES.each do |step_name|
        next unless step_analysis[step_name]

        step_data = step_analysis[step_name]
        puts sprintf(
               "%-20s %10d %10d %11.1f%% %11.1f%%",
               step_name.humanize,
               step_data["reached"],
               step_data["successful"],
               step_data["success_rate"],
               step_data["reach_rate"]
             )
      end

      if step_analysis["exhausted_all_steps"]["total"].positive?
        puts sprintf(
               "%-20s %10s %10d %11.1f%% %11.1f%%",
               "Exhausted All",
               "-",
               step_analysis["exhausted_all_steps"]["total"],
               0.0,
               step_analysis["exhausted_all_steps"]["percentage"]
             )
      end

      puts
      puts "Step Efficiency Analysis:"

      efficient_steps = []
      CASCADING_STEP_NAMES.each do |step_name|
        unless step_analysis[step_name] &&
                 step_analysis[step_name]["reached"].positive?
          next
        end

        efficiency = step_analysis[step_name]["success_rate"]
        efficient_steps << {
          name: step_name,
          efficiency: efficiency,
          reached: step_analysis[step_name]["reached"]
        }
      end

      efficient_steps
        .sort_by { |s| -s[:efficiency] }
        .each do |step|
          puts "├─ #{step[:name].humanize}: #{step[:efficiency]}% success rate (#{step[:reached]} reached)"
        end

      # Show failure breakdown for steps with significant failures
      puts "\nFailure Analysis:"
      CASCADING_STEP_NAMES.each do |step_name|
        next unless step_analysis[step_name]

        step_data = step_analysis[step_name]
        failures =
          step_data.select do |k, v|
            k.start_with?("failed_with_") && v.positive?
          end

        next unless failures.any?
        puts "#{step_name.humanize}:"
        failures.each do |failure_type, count|
          failure_name = failure_type.gsub("failed_with_", "").humanize
          percentage = (count.to_f / step_data["reached"] * 100).round(1)
          puts "  ├─ #{failure_name}: #{count} (#{percentage}%)"
        end
      end
    end

    def self.analyze_all_experiments
      PDSExperiments::PDSExperimentRunner::EXPERIMENTS.map do |experiment_name|
        new(experiment_name).analyze
      end
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

      cascading_results =
        all_results.select do |r|
          r[:experiment_name].include?("cascading") && r[:step_analysis]
        end

      if cascading_results.any?
        puts "\n=== Cascading Search Step Summary ==="
        cascading_results.each do |result|
          puts "\n#{result[:experiment_name]}:"
          result[:step_analysis].each do |step_name, data|
            next if step_name == "exhausted_all_steps" || data["reached"].zero?

            puts "  #{step_name}: #{data["successful"]}/#{data["reached"]} (#{data["success_rate"]}%)"
          end
        end
      end

      all_results
    end

    def self.compare_cascading_searches
      cascading_experiments =
        PDSExperiments::PDSExperimentRunner::EXPERIMENTS.select do |e|
          e.include?("cascading")
        end
      results =
        cascading_experiments
          .map { |exp| new(exp).analyze }
          .reject { |r| r[:error] }

      puts "=== Cascading Search Comparison ==="
      results.each do |result|
        puts "\n#{result[:experiment_name]}:"
        puts "  Overall Coverage: #{result[:coverage_percentage]}%"

        next unless result[:step_analysis]
        puts "  Step Breakdown:"
        CASCADING_STEP_NAMES.each do |step_name|
          step_data = result[:step_analysis][step_name]
          next unless step_data && step_data["reached"].positive?

          puts "    #{step_name}: #{step_data["success_rate"]}% success (#{step_data["reached"]} reached)"
        end

        exhausted = result[:step_analysis]["exhausted_all_steps"]
        if exhausted["total"].positive?
          puts "    Exhausted: #{exhausted["percentage"]}%"
        end
      end

      results
    end

    private

    attr_reader :experiment_name

    def cascading_search?
      experiment_name.include?("cascading")
    end

    def fetch_counters
      counters = {}

      COUNTER_NAMES.each do |counter_name|
        cache_key = "pds_experiment:#{experiment_name}:#{counter_name}"
        counters[counter_name] = Rails.cache.read(cache_key) || 0
      end

      fetch_step_counters(counters) if cascading_search?

      counters
    end

    def fetch_step_counters(counters)
      CASCADING_STEP_NAMES.each do |step_name|
        %w[reached successful].each do |metric|
          key = "step_#{step_name}_#{metric}"
          cache_key = "pds_experiment:#{experiment_name}:#{key}"
          counters[key] = Rails.cache.read(cache_key) || 0
        end

        %w[patient_not_found too_many_matches].each do |error_type|
          key = "step_#{step_name}_failed_with_#{error_type}"
          cache_key = "pds_experiment:#{experiment_name}:#{key}"
          counters[key] = Rails.cache.read(cache_key) || 0
        end
      end

      cache_key =
        "pds_experiment:#{experiment_name}:step_exhausted_all_steps_total"
      counters["exhausted_all_steps_total"] = Rails.cache.read(cache_key) || 0
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
