# frozen_string_literal: true

module HasDoseVolume
  extend ActiveSupport::Concern

  def full_dose? = full_dose == true

  def half_dose? = full_dose == false

  def dose_volume_ml
    return nil if vaccine.nil? || full_dose.nil?

    if full_dose?
      vaccine.dose_volume_ml
    elsif half_dose?
      vaccine.dose_volume_ml * 0.5
    end
  end
end
