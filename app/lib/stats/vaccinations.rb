# frozen_string_literal: true

class Stats::Vaccinations
  def initialize(
    since_date: nil,
    until_date: nil,
    programme_type: nil,
    outcome: nil,
    teams: nil
  )
    @since_date = since_date
    @until_date = until_date
    @programme_type = programme_type
    @outcome = outcome
    @teams = teams
  end

  def call
    vaccinations = build_base_query
    results = vaccinations.group(:programme_type, :outcome).count
    transform_results(results)
  end

  def self.call(...) = new(...).call

  private

  attr_reader :since_date, :until_date, :programme_type, :outcome, :teams

  def build_base_query
    vaccinations = VaccinationRecord.recorded_in_service

    vaccinations =
      vaccinations.joins(:session).where(sessions: { team: teams }) if teams

    vaccinations =
      vaccinations.where(
        "vaccination_records.created_at >= ?",
        Date.parse(since_date)
      ) if since_date

    vaccinations =
      vaccinations.where(
        "vaccination_records.created_at <= ?",
        Date.parse(until_date)
      ) if until_date

    vaccinations = vaccinations.where(programme_type:) if programme_type
    vaccinations = vaccinations.where(outcome: outcome) if outcome

    vaccinations
  end

  def transform_results(results)
    programme_results = {}

    results.each do |(programme_type, outcome_value), count|
      programme_results[programme_type] ||= {}
      programme_results[programme_type][outcome_value] = count
    end

    programme_results
  end
end
