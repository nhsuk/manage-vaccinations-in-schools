# frozen_string_literal: true

class AppVaccinationsSummaryTableComponent < ViewComponent::Base
  def initialize(current_user:, session:, request_session:)
    @current_user = current_user
    @session = session
    @request_session = request_session
  end

  private

  attr_reader :session, :request_session, :current_user

  delegate :govuk_table, to: :helpers

  def count_by_vaccine
    vaccines = session.vaccines.active.includes(:programme).order(:brand)

    vaccination_records =
      session
        .vaccination_records
        .includes(vaccine: :programme)
        .administered
        .where(performed_by_user: current_user)
        .where(performed_at: Date.current.all_day)

    results = vaccines.index_with { 0 }

    vaccination_records.find_each do |vaccination_record|
      vaccine = vaccination_record.vaccine

      results[vaccine] ||= 0
      results[vaccine] += 1
    end

    results
  end

  def default_batch(vaccine)
    batch_id =
      request_session.dig(
        :todays_batch,
        vaccine.programme.type,
        vaccine.method,
        :id
      )

    Batch.where(vaccine:).find_by(id: batch_id)
  end
end
