# frozen_string_literal: true

class AppSessionDatesTableComponent < ViewComponent::Base
  def initialize(session)
    @session = session
    @patient_ids = session.patients.pluck(:id)
  end

  def session_column_names
    programmes.flat_map do |programme|
      if programme.has_multiple_vaccine_methods?
        [
          "#{programme.name_in_sentence.titlecase} (nasal spray)",
          "#{programme.name_in_sentence.titlecase} (injection)"
        ]
      else
        programme.name_in_sentence
      end
    end
  end

  def rows
    session_dates_rows + [total_row]
  end

  private

  attr_reader :session, :patient_ids

  delegate :govuk_table, to: :helpers
  delegate :programmes, to: :session

  def session_dates_rows
    @session_dates_rows ||=
      session.session_dates.map do |session_date|
        {
          label: session_date.value.strftime("%e %B %Y"),
          tallies: tally_vaccination_counts_for_date(session_date, programmes)
        }
      end
  end

  def total_row
    { label: "Total", tallies: compute_total_tallies }
  end

  def tally_vaccination_counts_for_date(session_date, programmes)
    programmes.flat_map do |programme|
      records_for_date =
        vaccination_records(programme).fetch(session_date.value, [])

      if programme.has_multiple_vaccine_methods?
        nasal_spray_count =
          records_for_date.count { it.vaccine.method == "nasal" }
        injection_count =
          records_for_date.count { it.vaccine.method == "injection" }
        [nasal_spray_count, injection_count]
      else
        [records_for_date.count]
      end
    end
  end

  def compute_total_tallies
    totals = Array.new(session_column_names.length, 0)

    session_dates_rows.each do |row|
      row[:tallies].each_with_index { |tally, index| totals[index] += tally }
    end

    totals
  end

  def vaccination_records(programme)
    @vaccination_records ||= {}
    @vaccination_records[programme.id] ||= VaccinationRecord
      .where(programme:, patient_id: patient_ids, outcome: :administered)
      .group_by { it.performed_at.to_date }
  end

  def patients_for_programme(programme)
    @patients_for_programmes ||= {}
    @patients_for_programmes[programme.id] ||= begin
      birth_academic_years = session.programme_birth_academic_years[programme]
      session.patients.where(birth_academic_year: birth_academic_years)
    end
  end
end
