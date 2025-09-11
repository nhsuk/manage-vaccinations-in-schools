# frozen_string_literal: true

class AppVaccinationsSummaryTableComponent < ViewComponent::Base
  def initialize(current_user:, session:, request_session:)
    @current_user = current_user
    @session = session
    @request_session = request_session
  end

  delegate :govuk_table, to: :helpers

  def tally_results
    administered = session.vaccination_records.includes(:vaccine).administered

    results = initialize_results_hash
    populate_results(results, administered) if administered.any?

    results
  end

  private

  attr_reader :session, :request_session, :current_user

  def initialize_results_hash
    results = {}

    session
      .vaccines
      .includes(:programme)
      .find_each do |vaccine|
        results[vaccine.brand] = {
          count: 0,
          programme: vaccine.programme,
          vaccine_method: vaccine.method,
          default_batch: default_batch(vaccine)
        }
      end

    results
  end

  def populate_results(results, administered_vaccination_records)
    administered_vaccination_records
      .where(performed_by_user: current_user)
      .find_each do |vaccination_record|
        results[vaccination_record.vaccine.brand][:count] += 1
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
    batch = Batch.find_by(id: batch_id)

    return unless batch && batch.vaccine.brand == vaccine.brand

    batch.name
  end
end
