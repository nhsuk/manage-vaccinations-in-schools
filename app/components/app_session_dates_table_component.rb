# frozen_string_literal: true

class AppSessionDatesTableComponent < ViewComponent::Base
  def initialize(session)
    @session = session
  end

  def session_column_names
    @session_column_names ||= build_column_names
  end

  def rows
    session_dates_rows + [total_row]
  end

  private

  attr_reader :session

  delegate :govuk_table, to: :helpers
  delegate :programmes, to: :session

  def build_column_names
    programmes.flat_map do |programme|
      if programme.has_multiple_vaccine_methods?
        base_name = programme.name_in_sentence.titlecase
        ["#{base_name} (nasal spray)", "#{base_name} (injection)"]
      else
        programme.name_in_sentence
      end
    end
  end

  def session_dates_rows
    @session_dates_rows ||=
      session.session_dates.map do |session_date|
        {
          label: session_date.value.strftime("%e %B %Y"),
          tallies: tally_vaccination_counts_for_date(session_date)
        }
      end
  end

  def total_row
    { label: "Total", tallies: compute_total_tallies }
  end

  def tally_vaccination_counts_for_date(session_date)
    programmes.flat_map do |programme|
      vaccination_records_for_date =
        vaccination_records_by_date(programme).fetch(session_date.value, [])

      if programme.has_multiple_vaccine_methods?
        count_by_vaccine_method(vaccination_records_for_date)
      else
        [vaccination_records_for_date.count]
      end
    end
  end

  def count_by_vaccine_method(vaccination_records)
    nasal_spray_count =
      vaccination_records.count { it.vaccine.method == "nasal" }
    injection_count =
      vaccination_records.count { it.vaccine.method == "injection" }
    [nasal_spray_count, injection_count]
  end

  def compute_total_tallies
    totals = Array.new(session_column_names.length, 0)

    session_dates_rows.each do |row|
      row[:tallies].each_with_index { |tally, index| totals[index] += tally }
    end

    totals
  end

  def vaccination_records_by_date(programme)
    @vaccination_records_by_date ||= {}
    @vaccination_records_by_date[programme.id] ||= VaccinationRecord
      .where(
        programme: programme,
        session: session,
        patient_id: patients_for_programme(programme),
        outcome: :administered
      )
      .group_by { |record| record.performed_at.to_date }
  end

  def patients_for_programme(programme)
    @patients_for_programme ||= {}
    @patients_for_programme[programme.id] ||= begin
      birth_academic_years = session.programme_birth_academic_years[programme]
      session.patients.where(birth_academic_year: birth_academic_years)
    end
  end
end
