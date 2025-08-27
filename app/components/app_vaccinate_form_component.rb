# frozen_string_literal: true

class AppVaccinateFormComponent < ViewComponent::Base
  def initialize(form)
    super

    @form = form
  end

  private

  attr_reader :form

  delegate :patient_session, :programme, to: :form
  delegate :patient, :session, to: :patient_session
  delegate :academic_year, to: :session

  def url
    session_patient_programme_vaccinations_path(session, patient, programme)
  end

  def vaccine_methods
    patient.approved_vaccine_methods(programme:, academic_year:)
  end

  def dose_sequence
    programme.default_dose_sequence
  end

  COMMON_DELIVERY_SITES = {
    "injection" => %w[left_arm_upper_position right_arm_upper_position],
    "nasal" => %w[nose]
  }.freeze

  CommonDeliverySite = Struct.new(:value, :label)

  def common_delivery_site_options(vaccine_method)
    common_delivery_sites = COMMON_DELIVERY_SITES.fetch(vaccine_method)

    options =
      common_delivery_sites.map do |value|
        label = VaccinationRecord.human_enum_name(:delivery_site, value)
        CommonDeliverySite.new(value:, label:)
      end

    has_more_delivery_sites =
      (
        Vaccine::AVAILABLE_DELIVERY_SITES.fetch(vaccine_method) -
          common_delivery_sites
      ).present?

    if has_more_delivery_sites
      options << CommonDeliverySite.new(value: "other", label: "Other")
    end

    options
  end

  def vaccination_name
    vaccination =
      if programme.has_multiple_vaccine_methods?
        Vaccine.human_enum_name(:method, vaccine_methods.first).downcase
      else
        "vaccination"
      end

    "#{programme.name_in_sentence} #{vaccination}"
  end

  def ask_not_taking_medication? = programme.doubles? || programme.flu?

  def ask_not_pregnant? = programme.td_ipv?

  def ask_asthma_flare_up? = vaccine_methods.include?("nasal")
end
