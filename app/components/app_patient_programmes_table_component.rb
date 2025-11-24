# frozen_string_literal: true

class AppPatientProgrammesTableComponent < ViewComponent::Base
  def initialize(patient, programmes:)
    @patient = patient
    @programmes = programmes
  end

  def call
    govuk_table(
      caption: CAPTION,
      head: HEADERS,
      rows:,
      first_cell_is_header: true
    )
  end

  private

  attr_reader :patient, :programmes

  delegate :govuk_table, to: :helpers

  CAPTION = "Vaccination programmes"
  HEADERS = ["Programme name", "Status", "Notes"].freeze

  def rows
    programmes.flat_map { |programme| rows_for_programme(programme:) }
  end

  def rows_for_programme(programme:)
    if programme.seasonal?
      seasonal_programme_rows(programme:)
    else
      non_seasonal_programme_rows(programme:)
    end
  end

  def seasonal_programme_rows(programme:)
    AcademicYear.all.map do |academic_year|
      build_row(programme:, academic_year:)
    end
  end

  def non_seasonal_programme_rows(programme:)
    academic_year = AcademicYear.pending
    [build_row(programme:, academic_year:)]
  end

  def build_row(programme:, academic_year:)
    [
      name_for_programme(programme:, academic_year:),
      status_for_programme(programme:, academic_year:),
      notes_for_programme(programme:, academic_year:)
    ]
  end

  def name_for_programme(programme:, academic_year:)
    if programme.seasonal?
      "#{programme.name} (winter #{academic_year})"
    else
      programme.name
    end
  end

  def status_for_programme(programme:, academic_year:)
    hash = vaccination_status_hash(programme:, academic_year:)
    tag.strong(hash[:text], class: "nhsuk-tag nhsuk-tag--#{hash[:colour]}")
  end

  def notes_for_programme(programme:, academic_year:)
    vaccination_status_hash(programme:, academic_year:)[
      :details_text
    ].presence || ""
  end

  def vaccination_status_hash(programme:, academic_year:)
    @vaccination_status_hash ||= {}
    @vaccination_status_hash[programme.type] ||= {}
    @vaccination_status_hash[programme.type][
      academic_year
    ] ||= PatientStatusResolver.new(
      patient,
      programme:,
      academic_year:
    ).vaccination
  end
end
