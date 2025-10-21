# frozen_string_literal: true

class InvalidateDelayTriagesJob < ApplicationJob
  queue_as :triages

  def perform
    patient_ids = Triage.should_be_invalidated.pluck(:patient_id).uniq

    return if patient_ids.empty?

    Triage.should_be_invalidated.invalidate_all

    StatusUpdater.call(patient: patient_ids)
  end
end
