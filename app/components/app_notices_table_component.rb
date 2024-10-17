# frozen_string_literal: true

class AppNoticesTableComponent < ViewComponent::Base
  def initialize(deceased_patients:)
    super

    @deceased_patients = deceased_patients
  end

  def render?
    deceased_patients.present?
  end

  private

  attr_reader :deceased_patients
end
