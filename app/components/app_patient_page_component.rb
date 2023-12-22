# frozen_string_literal: true

class AppPatientPageComponent < ViewComponent::Base
  include ApplicationHelper

  attr_reader :patient_session, :current_user

  def initialize(
    patient_session:,
    route:,
    triage: nil,
    vaccination_record: nil,
    current_user: nil
  )
    super

    @patient_session = patient_session
    @route = route
    @triage = triage
    @vaccination_record = vaccination_record
    @current_user = current_user
  end

  delegate :patient, to: :patient_session
  delegate :session, to: :patient_session
end
