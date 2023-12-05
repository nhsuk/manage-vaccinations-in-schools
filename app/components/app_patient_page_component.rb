# frozen_string_literal: true

class AppPatientPageComponent < ViewComponent::Base
  include ApplicationHelper

  attr_reader :patient_session, :consent

  def initialize(patient_session:, consent:, route:, vaccination_record: nil)
    super

    @patient_session = patient_session
    @consent = consent
    @vaccination_record = vaccination_record || VaccinationRecord.new
    @route = route
  end

  delegate :patient, to: :patient_session
  delegate :session, to: :patient_session
end
