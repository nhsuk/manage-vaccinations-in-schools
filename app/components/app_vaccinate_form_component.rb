# frozen_string_literal: true

class AppVaccinateFormComponent < ViewComponent::Base
  def initialize(vaccinate_form)
    super

    @vaccinate_form = vaccinate_form
  end

  private

  attr_reader :vaccinate_form

  delegate :patient_session, :programme, to: :vaccinate_form
  delegate :patient, :session, to: :patient_session

  def url
    session_patient_programme_vaccinations_path(session, patient, programme)
  end

  def delivery_method
    if patient.approved_vaccine_methods(programme:).include?("nasal")
      "nasal_spray"
    else
      "intramuscular"
    end
  end

  def dose_sequence
    programme.default_dose_sequence
  end

  COMMON_DELIVERY_SITES = {
    "intramuscular" => %w[left_arm_upper_position right_arm_upper_position],
    "nasal_spray" => %w[nose]
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

        if delivery_method.in?(Vaccine::INJECTION_DELIVERY_METHODS)
          options << CommonDeliverySite.new(value: "other", label: "Other")
        end

        options
      end
  end

  def vaccination_name
    vaccination =
      if programme.has_multiple_vaccine_methods?
        if delivery_method.in?(Vaccine::NASAL_DELIVERY_METHODS)
          "nasal spray"
        else
          "injection"
        end
      else
        "vaccination"
      end

    "#{programme.name_in_sentence} #{vaccination}"
  end

  def ask_not_taking_medication? = programme.doubles? || programme.flu?

  def ask_not_pregnant? = programme.td_ipv?

  def ask_asthma_flare_up? =
    delivery_method.in?(Vaccine::NASAL_DELIVERY_METHODS)
end
