# frozen_string_literal: true

class AppPatientTableComponent < ViewComponent::Base
  def initialize(patients, count: nil, heading: nil)
    super

    @patients = patients
    @count = count
    @heading = heading
  end

  private

  attr_reader :patients

  def heading
    @heading.presence || I18n.t("children", count: @count)
  end
end
