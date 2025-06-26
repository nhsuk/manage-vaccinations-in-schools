# frozen_string_literal: true

class AppPatientVaccinationTableComponent < ViewComponent::Base
  def initialize(patient, programme: nil, show_caption: false)
    super

    @patient = patient
    @programme = programme
    @show_caption = show_caption
  end

  private

  attr_reader :patient, :programme, :show_caption

  def show_programme = programme.nil?

  def vaccination_records
    patient
      .vaccination_records
      .then { programme ? it.where(programme:) : it }
      .includes(:location, :programme)
      .order(performed_at: :desc)
      .select(&:show_this_academic_year?)
  end
end
