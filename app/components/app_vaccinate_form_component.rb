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

  def delivery_method
    if patient.consent_status(programme:).vaccine_method_nasal?
      :nasal_spray
    else
      :intramuscular
    end
  end

  def dose_sequence
    programme.default_dose_sequence
  end

  COMMON_DELIVERY_SITES = {
    intramuscular: %w[left_arm_upper_position right_arm_upper_position],
    nasal_spray: %w[nose]
  }.freeze

  CommonDeliverySite = Struct.new(:value, :label)

  def common_delivery_sites_options
    @common_delivery_sites_options ||=
      begin
        options =
          COMMON_DELIVERY_SITES
            .fetch(delivery_method)
            .map do |value|
              label = VaccinationRecord.human_enum_name(:delivery_site, value)
              CommonDeliverySite.new(value:, label:)
            end

        if delivery_method == :intramuscular
          options << CommonDeliverySite.new(value: "other", label: "Other")
        end

        options
      end
  end
end
