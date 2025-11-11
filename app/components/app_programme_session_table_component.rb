# frozen_string_literal: true

class AppProgrammeSessionTableComponent < ViewComponent::Base
  def initialize(sessions, programme:, academic_year:)
    @sessions = sessions
    @programme = programme
    @academic_year = academic_year
  end

  private

  attr_reader :sessions, :programme, :academic_year

  delegate :govuk_table, to: :helpers

  def cohort_count(session:)
    format_number(patients(session:).count)
  end

  def no_response_scope(session:)
    patients(session:).has_consent_status(
      :no_response,
      programme:,
      academic_year:
    )
  end

  def no_response_count(session:)
    format_number(no_response_scope(session:).count)
  end

  def no_response_percentage(session:)
    format_percentage(
      no_response_scope(session:).count,
      patients(session:).count
    )
  end

  def triage_needed_count(session:)
    format_number(
      patients(session:).has_triage_status(
        :required,
        programme:,
        academic_year:
      ).count
    )
  end

  def vaccinated_scope(session:)
    session.vaccination_records.where_programme(programme).administered
  end

  def vaccinated_count(session:)
    format_number(vaccinated_scope(session:).count)
  end

  def vaccinated_percentage(session:)
    format_percentage(
      vaccinated_scope(session:).count,
      patients(session:).count
    )
  end

  def patients(session:)
    @patients ||= {}
    @patients[session] = session.patients.where(
      birth_academic_year: birth_academic_years(session:)
    )
  end

  def birth_academic_years(session:)
    @birth_academic_years ||= {}
    @birth_academic_years[
      session
    ] = session.programme_year_groups.birth_academic_years(programme)
  end

  def format_number(count) = count.to_s

  def format_percentage(count, total_count)
    return nil if total_count.zero?

    number_to_percentage(count / total_count.to_f * 100.0, precision: 0)
  end
end
