# frozen_string_literal: true

class AppPatientVaccinationTableComponent < ViewComponent::Base
  def initialize(patient, academic_year:, programme: nil, show_caption: false)
    @patient = patient
    @academic_year = academic_year
    @programme = programme
    @show_caption = show_caption
  end

  private

  delegate :govuk_table, to: :helpers

  attr_reader :patient, :academic_year, :programme, :show_caption

  def show_programme = programme.nil?

  def vaccination_records
    patient
      .vaccination_records
      .then { programme ? it.where_programme(programme) : it }
      .includes(:location)
      .order(performed_at: :desc)
      .select { it.show_in_academic_year?(academic_year) }
  end
end
