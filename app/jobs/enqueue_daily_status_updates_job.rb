# frozen_string_literal: true

class EnqueueDailyStatusUpdatesJob
  include Sidekiq::Job

  def perform
    scope = PatientLocation.joins_sessions.select(:id, :patient_id).distinct

    scope.find_in_batches(batch_size: 1_000) do |batch|
      StatusUpdaterJob.perform_later(patient: batch.map(&:patient_id))
    end
  end
end
