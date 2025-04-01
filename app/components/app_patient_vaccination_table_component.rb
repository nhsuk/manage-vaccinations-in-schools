# frozen_string_literal: true

class AppPatientVaccinationTableComponent < ViewComponent::Base
  def initialize(patient)
    super

    @patient = patient
  end

  private

  attr_reader :patient

  def vaccination_records
    patient
      .vaccination_records
      .administered
      .includes(:location, :programme, :vaccine)
      .order(performed_at: :desc)
  end
end
