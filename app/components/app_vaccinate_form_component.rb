# frozen_string_literal: true

class AppVaccinateFormComponent < ViewComponent::Base
  def initialize(patient_session:, programme:, vaccinate_form:)
    super

    @patient_session = patient_session
    @programme = programme
    @vaccinate_form = vaccinate_form
  end

  def render?
    patient.consent_given_and_safe_to_vaccinate?(programme:) &&
      patient_session.register_outcome.attending?
  end

  private

  attr_reader :patient_session, :programme, :vaccinate_form

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
    programme.vaccinated_dose_sequence == 1 ? 1 : nil
  end

  def common_delivery_sites_options
    options =
      vaccine.common_delivery_sites.map do |site|
        OpenStruct.new(
          value: site,
          label:
            t(
              site,
              scope: "activerecord.attributes.vaccination_record.delivery_sites"
            )
        )
      end

    options + [OpenStruct.new(value: "other", label: "Other")]
  end
end
