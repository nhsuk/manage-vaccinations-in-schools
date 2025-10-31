# frozen_string_literal: true

class AppPatientSessionSectionComponent < ViewComponent::Base
  def initialize(patient:, session:, programme:)
    @patient = patient
    @session = session
    @programme = programme
  end

  private

  attr_reader :patient, :session, :programme

  delegate :academic_year, to: :session

  def colour = resolved_status.fetch(:colour)

  def heading = "#{programme.name}: #{resolved_status.fetch(:text)}"

  def patient_status_resolver
    PatientStatusResolver.new(patient, programme:, academic_year:)
  end
end
