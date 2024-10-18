# frozen_string_literal: true

class AppNoticesTableComponent < ViewComponent::Base
  def initialize(deceased_patients:, restricted_patients:)
    super

    @deceased_patients = deceased_patients
    @restricted_patients = restricted_patients
  end

  def render?
    @deceased_patients.present? || @restricted_patients.present?
  end

  private

  def notices
    (deceased_notices + restricted_notices).sort_by { _1[:date] }.reverse
  end

  def deceased_notices
    @deceased_patients.map do |patient|
      {
        patient:,
        date_time: patient.date_of_death_recorded_at,
        message: "Record updated with child’s date of death"
      }
    end
  end

  def restricted_notices
    @restricted_patients.map do |patient|
      {
        patient:,
        date_time: patient.restricted_at,
        message: "Record flagged as sensitive"
      }
    end
  end
end
