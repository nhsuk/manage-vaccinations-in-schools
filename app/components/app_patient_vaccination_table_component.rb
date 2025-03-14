# frozen_string_literal: true

class AppPatientVaccinationTableComponent < ViewComponent::Base
  def initialize(patient, show_caption:, show_programme:)
    super

    @patient = patient
    @show_caption = show_caption
    @show_programme = show_programme
  end

  private

  attr_reader :patient, :show_caption, :show_programme

  def vaccination_records
    patient
      .vaccination_records
      .includes(:location, :programme)
      .order(performed_at: :desc)
  end
end
