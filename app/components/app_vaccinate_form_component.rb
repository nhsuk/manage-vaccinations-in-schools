# frozen_string_literal: true

class AppVaccinateFormComponent < ViewComponent::Base
  def initialize(form)
    @form = form
  end

  private

  attr_reader :form

  delegate :current_user, :patient, :session, :programme, to: :form
  delegate :academic_year, :team, to: :session

  def url
    session_patient_programme_vaccinations_path(session, patient, programme)
  end

  def vaccine_criteria
    @vaccine_criteria ||= patient.vaccine_criteria(programme:, academic_year:)
  end

  def vaccine_methods
    @vaccine_methods ||=
      begin
        approved_vaccine_methods = vaccine_criteria.vaccine_methods

        if current_user.is_nurse? || current_user.is_prescriber?
          return approved_vaccine_methods
        end
        return [] unless healthcare_assistant?

        approved_vaccine_methods.select do |vaccine_method|
          (
            vaccine_method == "injection" && session.national_protocol_enabled?
          ) || (vaccine_method == "nasal" && session.pgd_supply_enabled?) ||
            (
              session.psd_enabled? &&
                patient.has_patient_specific_direction?(
                  academic_year:,
                  programme:,
                  team:,
                  vaccine_method:
                )
            )
        end
      end
  end

  def show_supplied_by_user_id_outside_vaccine_method?
    @show_supplied_by_user_id_outside_vaccine_method ||=
      healthcare_assistant? &&
        vaccine_methods.none? do |vaccine_method|
          has_patient_specific_direction?(vaccine_method:)
        end
  end

  def show_supplied_by_user_id_inside_vaccine_method?(vaccine_method)
    return false if show_supplied_by_user_id_outside_vaccine_method?

    healthcare_assistant? && !has_patient_specific_direction?(vaccine_method:)
  end

  def has_patient_specific_direction?(vaccine_method:)
    session.psd_enabled? &&
      patient.has_patient_specific_direction?(
        academic_year:,
        programme:,
        team:,
        vaccine_method:
      )
  end

  def healthcare_assistant? = current_user.is_healthcare_assistant?

  def dose_sequence = programme.default_dose_sequence

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

  def ask_not_taking_medication? =
    programme.doubles? || programme.flu? || programme.mmr?

  def ask_not_pregnant? = programme.td_ipv? || programme.mmr?

  def ask_asthma_flare_up? = vaccine_methods.include?("nasal")

  def ask_blood_transfusion? = programme.mmr?

  def ask_tb_skin_test? = programme.mmr?

  def ask_yellow_fever_or_chickenpox? = programme.mmr?
end
