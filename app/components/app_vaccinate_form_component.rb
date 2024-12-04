# frozen_string_literal: true

class AppVaccinateFormComponent < ViewComponent::Base
  def initialize(patient_session:, vaccinate_form:, section:, tab:)
    super

    @patient_session = patient_session
    @vaccinate_form = vaccinate_form
    @section = section
    @tab = tab
  end

  def render?
    patient_session.next_step == :vaccinate && session.open? &&
      (patient_session.attending_today? || false)
  end

  private

  attr_reader :patient_session, :vaccinate_form

  delegate :patient, :session, to: :patient_session

  def url
    session_patient_vaccinations_path(
      session,
      patient,
      section: @section,
      tab: @tab
    )
  end

  # TODO: this code will need to be revisited in future as it only really
  # works for HPV, where we only have one vaccine. It is likely to fail for
  # the Doubles programme as that has 2 vaccines. It is also likely to fail
  # for the flu programme for the SAIS organisations that offer both nasal and
  # injectable vaccines.

  def programme
    patient_session.programmes.first
  end

  def vaccine
    programme.vaccines.active.first
  end

  def dose_sequence
    1
  end
end
