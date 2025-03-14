# frozen_string_literal: true

class AppPatientPageComponent < ViewComponent::Base
  include ApplicationHelper

  attr_reader :current_user, :patient_session, :programme

  def initialize(patient_session:, programme:, current_user: nil)
    super

    @patient_session = patient_session
    @programme = programme
    @current_user = current_user
  end

  delegate :patient, :session, to: :patient_session
end
