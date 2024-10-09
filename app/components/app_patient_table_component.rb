# frozen_string_literal: true

class AppPatientTableComponent < ViewComponent::Base
  def initialize(patients, count:)
    super

    @patients = patients
    @count = count
  end

  private

  attr_reader :patients

  def heading
    I18n.t("children", count: @count)
  end
end
