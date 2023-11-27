# frozen_string_literal: true

class AppPatientPageComponent < ViewComponent::Base
  include ApplicationHelper

  attr_reader :patient_session

  def initialize(patient_session:)
    super

    @patient_session = patient_session
  end

  delegate :patient, to: :patient_session
  delegate :session, to: :patient_session
end
