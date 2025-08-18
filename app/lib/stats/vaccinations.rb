# frozen_string_literal: true

class Stats::Vaccinations
  def initialize(
    since_date: nil,
    until_date: nil,
    programme: nil,
    outcome: nil,
    teams: nil
  )
    @since_date = since_date
    @until_date = until_date
    @programme = programme
    @outcome = outcome
    @teams = teams
  end

  def call
    vaccinations = build_base_query
    results = vaccinations.group(:programme_id, :outcome).count
    transform_results(results)
  end

  def self.call(...) = new(...).call

  private

  attr_reader :since_date, :until_date, :programme, :outcome, :teams

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

    if programme
      programme_record = Programme.find_by(type: programme)
      vaccinations = vaccinations.where(programme_id: programme_record.id)
    end

    vaccinations = vaccinations.where(outcome: outcome) if outcome

    vaccinations
  end

  def transform_results(results)
    programme_results = {}

    if programme
      results.each do |(_programme_id, outcome_value), count|
        programme_results[programme] ||= {}
        programme_results[programme][outcome_value] = count
      end
    else
      programme_ids = results.keys.map(&:first).uniq
      programmes = Programme.where(id: programme_ids).index_by(&:id)

      results.each do |(programme_id, outcome_value), count|
        programme_record = programmes[programme_id]
        next unless programme_record

        programme_type = programme_record.type
        programme_results[programme_type] ||= {}
        programme_results[programme_type][outcome_value] = count
      end
    end
    programme_results
  end
end
