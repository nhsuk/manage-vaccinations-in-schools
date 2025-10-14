# frozen_string_literal: true

class EnqueueVaccinationsSearchInNHSJob < ApplicationJob
  queue_as :immunisations_api_search

  def perform(programme_types: default_programme_types)
    patient_ids = Set.new

    if Flipper.enabled?(:imms_api_enqueue_session_searches)
      patient_ids += patient_ids_session_searches(programme_types:)
    end

    if Flipper.enabled?(:imms_api_enqueue_rolling_searches)
      patient_ids += patient_ids_for_rolling_searches
    end

    if patient_ids.any?
      SearchVaccinationRecordsInNHSJob.perform_bulk(patient_ids.zip)
    end
  end

  private

  def default_programme_types = ["flu"].freeze
  def daily_enqueue_size_limit = 1000
  def rolling_search_period_in_days = 28

  def patient_ids_session_searches(programme_types:)
    scope =
      Session
        .has_any_programme_types_of(programme_types)
        .scheduled
        .then do
          it.where("sessions.send_invitations_at <= ?", 2.days.from_now).or(
            it.where("sessions.send_consent_requests_at <= ?", 2.days.from_now)
          )
        end

    scope.find_each.flat_map { |session| session.patients.pluck(:id) }
  end

  def patient_ids_for_rolling_searches
    patient_ids ||=
      Patient
        .where.not(
          id:
            PatientProgrammeVaccinationsSearch.where(
              "last_searched_at > ?",
              rolling_search_period_in_days.days.ago
            ).select(:patient_id)
        )
        .ids

    batch_size = (patient_ids.count.to_f / rolling_search_period_in_days).ceil
    batch_size = [batch_size, daily_enqueue_size_limit].max
    patient_ids.first(batch_size)
  end
end
