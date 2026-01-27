# frozen_string_literal: true

class AppVaccineAlreadyGivenLinkComponent < ViewComponent::Base
  attr_reader :patient, :programme, :session

  def initialize(programme:, patient:, session:)
    @patient = patient
    @programme = programme
    @session = session
  end

  def call
    tag.li(class: "app-action-list__item") do
      link_to(
        label,
        session_patient_programme_record_already_vaccinated_path(
          @session,
          @patient,
          @programme
        )
      )
    end
  end

  def render?
    programme &&
      helpers.policy(
        VaccinationRecord.new(patient:, session:, programme:)
      ).record_already_vaccinated?
  end

  private

  def label
    if @programme.mmr?
      if had_first_dose?
        "Record 2nd dose as already given"
      else
        "Record 1st dose as already given"
      end
    else
      "Record as already vaccinated"
    end
  end

  def had_first_dose?
    programme_status =
      @patient.programme_status(
        @programme,
        academic_year: session.academic_year
      )
    programme_status.dose_sequence.present? &&
      programme_status.dose_sequence > 1
  end
end
