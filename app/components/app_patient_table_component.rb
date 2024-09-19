# frozen_string_literal: true

class AppPatientTableComponent < ViewComponent::Base
  def initialize(patients)
    super

    @patients = patients
  end

  private

  attr_reader :patients

  def heading
    I18n.t("children", count: patients.count)
  end
end
