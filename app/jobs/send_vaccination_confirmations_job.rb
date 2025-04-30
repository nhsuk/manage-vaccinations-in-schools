# frozen_string_literal: true

class SendVaccinationConfirmationsJob < ApplicationJob
  include VaccinationMailerConcern

  queue_as :notifications

  def perform
    # Find the oldest record that has had a confirmation sent, and send confirmations for all subsequent records
    since =
      VaccinationRecord
        .kept
        .where.not(confirmation_sent_at: nil)
        .maximum(:created_at) || 24.hours.ago
    academic_year = Date.current.academic_year

    VaccinationRecord
      .includes(patient: { consents: :parent })
      .kept
      .where("created_at >= ?", since)
      .where(confirmation_sent_at: nil)
      .recorded_in_service
      .select { _1.academic_year == academic_year }
      .each do |vaccation_record|
        send_vaccination_confirmation(vaccation_record)
        vaccation_record.update_column(:confirmation_sent_at, Time.current)
      end
  end
end
