# frozen_string_literal: true

class ProcessPatientChangesetsJob < ApplicationJob
  include PDSAPIThrottlingConcern

  queue_as :imports

  def perform(patient_changeset, step_name = nil)
    step_name ||= first_step_name

    SemanticLogger.tagged(
      patient_changeset_id: patient_changeset.id,
      step: step_name
    ) do
      step = steps[step_name]

      result, pds_patient =
        search_for_patient(patient_changeset.child_attributes, step_name)
      patient_changeset.search_results << {
        step: step_name,
        result: result,
        nhs_number: pds_patient&.nhs_number,
        created_at: Time.current
      }.with_indifferent_access

      next_step = step[result]

      if result == :error || next_step.nil? || next_step == :give_up ||
           multiple_nhs_numbers_found?(patient_changeset)
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
        patient_changeset.save!
        raise "Recursive step detected: #{next_step}" if next_step == step_name
        enqueue_next_search(patient_changeset, next_step)
      else
        patient_changeset.save!
        raise "Unknown step: #{next_step}"
      end
    end
  end

  private

  def unique_nhs_numbers(patient_changeset)
    patient_changeset.search_results.pluck("nhs_number").compact.uniq
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
        no_matches: :fuzzy,
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
        no_matches: :fuzzy,
        one_match: :fuzzy,
        too_many_matches: :fuzzy,
        skip_step: :fuzzy,
        format_query: ->(query) { query[:family_name][3..] = "*" }
      },
      fuzzy: {
        no_matches: :give_up,
        one_match: :save_nhs_number_if_unique,
        too_many_matches: :save_nhs_number_if_unique,
        format_query: ->(query) do
          query[:fuzzy] = true
          # For fuzzy searches, history is the default. We get an error if we
          # try to set it to true explicitly
          query[:history] = nil
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
  rescue Faraday::TooManyRequestsError
    raise
  rescue Faraday::ClientError, Faraday::ServerError => e
    Rails.logger.error(
      "Error doing PDS search for patient changeset: #{e.message}"
    )
    Sentry.capture_exception(e)
    [:error, nil]
  end

  def enqueue_next_search(patient_changeset, next_step)
    ProcessPatientChangesetsJob.perform_later(patient_changeset, next_step)
  end

  def finish_processing(patient_changeset)
    patient_changeset.processed!
    patient_changeset.save!

    # TODO: Make this atomic
    if patient_changeset.import.changesets.pending.none?
      CommitPatientChangesetsJob.perform_later(patient_changeset.import)
    end
  end
end
