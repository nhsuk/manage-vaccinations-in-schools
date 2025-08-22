# frozen_string_literal: true

class ProcessPatientChangesetsJob < ApplicationJob
  include PDSAPIThrottlingConcern

  queue_as :imports

  def perform(patient_changeset, step_name = nil)
    SemanticLogger.tagged(patient_changeset_id: patient_changeset.id) do
      step_name ||= first_step_name
      step = steps[step_name]

      result, pds_patient =
        search_for_patient(patient_changeset.child_attributes, step_name)
      patient_changeset.search_results << {
        step: step_name,
        result: result,
        nhs_number: pds_patient&.nhs_number
      }

      if multiple_nhs_numbers_found?(patient_changeset)
        finish_processing(patient_changeset)
      end

      next_step = step[result]

      if next_step == :give_up
        finish_processing(patient_changeset)
      elsif next_step == :save_nhs_number_if_unique
        if nhs_number_is_unique_across_searches?(patient_changeset)
          unique_nhs_number = get_unique_nhs_number(patient_changeset)
          if unique_nhs_number
            patient_changeset.child_attributes["nhs_number"] = unique_nhs_number
            patient_changeset.pds_nhs_number = unique_nhs_number
          end
        end
        finish_processing(patient_changeset)
      elsif next_step.in?(steps.keys)
        raise "Recursive step detected: #{next_step}" if next_step == step_name
        enqueue_next_search(patient_changeset, next_step)
      elsif result == :no_postcode
        finish_processing(patient_changeset)
      else
        raise "Unknown step: #{next_step}"
      end
    end
  end

  private

  def unique_nhs_numbers(patient_changeset)
    patient_changeset.search_results.pluck(:nhs_number).compact.uniq
  end

  def get_unique_nhs_number(patient_changeset)
    numbers = unique_nhs_numbers(patient_changeset)
    numbers.count == 1 ? numbers.first : nil
  end

  def nhs_number_is_unique_across_searches?(patient_changeset)
    unique_nhs_numbers(patient_changeset).count == 1
  end

  def multiple_nhs_numbers_found?(patient_changeset)
    unique_nhs_numbers(patient_changeset).count > 1
  end

  def first_step_name
    :no_fuzzy_with_history
  end

  def steps
    {
      no_fuzzy_with_history: {
        no_matches: :no_fuzzy_with_wildcard_postcode,
        one_match: :save_nhs_number_if_unique,
        too_many_matches: :no_fuzzy_without_history
      },
      no_fuzzy_without_history: {
        no_matches: :fuzzy_without_history,
        one_match: :save_nhs_number_if_unique,
        too_many_matches: :give_up,
        format_query: ->(query) { query.merge(history: false) }
      },
      no_fuzzy_with_wildcard_postcode: {
        no_matches: :no_fuzzy_with_wildcard_given_name,
        one_match: :no_fuzzy_with_wildcard_given_name,
        too_many_matches: :no_fuzzy_with_wildcard_given_name,
        format_query: ->(query) { query[:address_postcode][2..] = "*" }
      },
      no_fuzzy_with_wildcard_given_name: {
        no_matches: :no_fuzzy_with_wildcard_family_name,
        one_match: :no_fuzzy_with_wildcard_family_name,
        too_many_matches: :no_fuzzy_with_wildcard_family_name,
        skip_step: :no_fuzzy_with_wildcard_family_name,
        format_query: ->(query) { query[:given_name][3..] = "*" }
      },
      no_fuzzy_with_wildcard_family_name: {
        no_matches: :fuzzy_without_history,
        one_match: :fuzzy_without_history,
        too_many_matches: :fuzzy_without_history,
        skip_step: :fuzzy_without_history,
        format_query: ->(query) { query[:family_name][3..] = "*" }
      },
      fuzzy_without_history: {
        no_matches: :fuzzy_with_history,
        one_match: :save_nhs_number_if_unique,
        too_many_matches: :save_nhs_number_if_unique,
        format_query: ->(query) do
          query[:fuzzy] = true
          query[:history] = false
        end
      },
      fuzzy_with_history: {
        no_matches: :give_up,
        one_match: :save_nhs_number_if_unique,
        too_many_matches: :save_nhs_number_if_unique,
        format_query: ->(query) do
          query[:fuzzy] = true
          query.delete(:history)
        end
      }
    }
  end

  def search_for_patient(attrs, step_name)
    return :no_postcode, nil if attrs["address_postcode"].blank?

    case step_name
    when :no_fuzzy_with_wildcard_given_name
      return :skip_step, nil if attrs["given_name"].length <= 3
    when :no_fuzzy_with_wildcard_family_name
      return :skip_step, nil if attrs["family_name"].length <= 3
    end

    query = {
      family_name: attrs["family_name"].dup,
      given_name: attrs["given_name"].dup,
      date_of_birth: attrs["date_of_birth"].dup,
      address_postcode: attrs["address_postcode"].dup,
      history: true,
      fuzzy: false
    }
    if steps[step_name][:format_query].respond_to?(:call)
      result = steps[step_name][:format_query].call(query)
      query = result if result.is_a?(Hash)
    end

    patient = PDS::Patient.search(**query)
    return :no_matches, nil if patient.nil?

    [:one_match, patient]
  rescue NHS::PDS::PatientNotFound
    [:no_matches, nil]
  rescue NHS::PDS::TooManyMatches
    [:too_many_matches, nil]
  rescue Faraday::ClientError, Faraday::ServerError => e
    Rails.logger.error(
      "Error doing PDS search for patient changeset: #{e.message}"
    )
    Sentry.capture_exception(e)
    [:error, nil]
  end

  def enqueue_next_search(patient_changeset, next_step)
    if patient_changeset.import.slow?
      ProcessPatientChangesetsJob.perform_later(patient_changeset, next_step)
    else
      ProcessPatientChangesetsJob.perform_now(patient_changeset, next_step)
    end
  end

  def finish_processing(patient_changeset)
    patient_changeset.processed!
    patient_changeset.save!

    # TODO: Make this atomic
    if patient_changeset.import.changesets.pending.none?
      if patient_changeset.import.slow?
        CommitPatientChangesetsJob.perform_later(patient_changeset.import)
      else
        CommitPatientChangesetsJob.perform_now(patient_changeset.import)
      end
    end
  end
end
