# frozen_string_literal: true

class AppPatientProgrammeVaccinationCardComponent < ViewComponent::Base
  def initialize(patient, academic_year:, programme: nil, show_caption: false)
    @patient = patient
    @academic_year = academic_year
    @programme = programme
    @show_caption = show_caption
  end

  private

  delegate :govuk_table, :vaccination_record_source, to: :helpers

  attr_reader :patient, :academic_year, :programme, :show_caption

  def vaccination_records
    patient
      .vaccination_records
      .for_programme(programme)
      .includes(:location)
      .order_by_performed_at
      .select { it.show_in_academic_year?(academic_year) }
  end

  def formatted_age_when(vaccination_record)
    age = patient.age_years(now: vaccination_record.performed_at)
    pluralize(age, "year")
  end

  def programme_status_tag
    resolved_status =
      PatientProgrammeStatusResolver.call(
        patient,
        programme_type: programme.type,
        academic_year: AcademicYear.current
      )

    AppAttachedTagsComponent.new(
      resolved_status.fetch(:prefix) => resolved_status
    )
  end
end
