# frozen_string_literal: true

class AppVaccinateFormComponent < ViewComponent::Base
  def initialize(vaccinate_form)
    super

    @vaccinate_form = vaccinate_form
  end

  def render?
    patient.consent_given_and_safe_to_vaccinate?(programme:) &&
      (
        patient_session.registration_status&.attending? ||
          patient_session.registration_status&.completed? || false
      )
  end

  private

  attr_reader :vaccinate_form

  delegate :patient_session, :programme, to: :vaccinate_form
  delegate :patient, :session, to: :patient_session

  def url
    session_patient_programme_vaccinations_path(session, patient, programme)
  end

  # TODO: this code will need to be revisited in future as it only really
  # works for HPV, where we only have one vaccine. It is likely to fail for
  # the flu programme for the SAIS organisations that offer both nasal and
  # injectable vaccines.

  def vaccine
    programme.vaccines.active.first
  end

  def delivery_method
    :intramuscular
  end

  def dose_sequence
    programme.default_dose_sequence
  end

  def common_delivery_sites_options
    options =
      programme.common_delivery_sites.map do
        OpenStruct.new(
          value: it,
          label: VaccinationRecord.human_enum_name(:delivery_site, it)
        )
      end

    options + [OpenStruct.new(value: "other", label: "Other")]
  end
end
