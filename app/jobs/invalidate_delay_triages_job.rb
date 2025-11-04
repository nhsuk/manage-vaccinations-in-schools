# frozen_string_literal: true

class InvalidateDelayTriagesJob < ApplicationJob
  queue_as :triages

  def perform(delay_triage: nil)
    if delay_triage
      delay_triage.update!(invalidated_at: Time.current)
      keep_in_triage!(delay_triage)
      StatusUpdater.call(patient: delay_triage.patient)
    else
      delayed_triages = Triage.should_be_invalidated
      patient_ids = delayed_triages.pluck(:patient_id).uniq

      return if patient_ids.empty?

      ActiveRecord::Base.transaction do
        delayed_triages.find_each do |delay_triage|
          keep_in_triage!(delay_triage)
        end

        delayed_triages.invalidate_all
      end

      StatusUpdater.call(patient: patient_ids)
    end
  end

  def keep_in_triage!(delay_triage)
    Triage.create!(
      status: "keep_in_triage",
      notes: "The previous delay triage has expired",
      academic_year: delay_triage.academic_year,
      team_id: delay_triage.team_id,
      patient_id: delay_triage.patient_id,
      programme_id: delay_triage.programme_id,
      performed_by_user_id: delay_triage.performed_by_user_id
    )
  end
end
