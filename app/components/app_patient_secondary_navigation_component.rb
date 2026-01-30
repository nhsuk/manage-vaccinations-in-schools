# frozen_string_literal: true

class AppPatientSecondaryNavigationComponent < ViewComponent::Base
  def initialize(patient:, current_user:)
    @patient = patient
    @current_user = current_user
  end

  def render?
    helpers.policy(patient).log?
  end

  def call
    render AppSecondaryNavigationComponent.new do |nav|
      nav.with_item(
        href: patient_path(patient),
        text: "Child record",
        selected: true
      )
      current_user.programmes.flat_map do |programme|
        nav.with_item(href: patient_path(patient), text: programme.name)
      end
    end
  end

  private

  attr_reader :patient, :current_user
end
