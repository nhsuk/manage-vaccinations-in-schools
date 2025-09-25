# frozen_string_literal: true

class StatusGenerator::Consent
  def initialize(
    programme:,
    academic_year:,
    patient:,
    consents:,
    vaccination_records:
  )
    @programme = programme
    @academic_year = academic_year
    @patient = patient
    @consents = consents
    @vaccination_records = vaccination_records
  end

  def status
    if status_should_be_given?
      :given
    elsif status_should_be_refused?
      :refused
    elsif status_should_be_conflicts?
      :conflicts
    elsif status_should_be_no_response?
      :no_response
    else
      :not_required
    end
  end

  def status_changed_at
    consents_for_status.map(&:submitted_at).max
  end

  def vaccine_methods
    status_should_be_given? ? agreed_vaccine_methods : []
  end

  private

  attr_reader :programme,
              :academic_year,
              :patient,
              :consents,
              :vaccination_records

  def vaccinated?
    @vaccinated ||=
      VaccinatedCriteria.new(
        programme:,
        academic_year:,
        patient:,
        vaccination_records:
      ).vaccinated?
  end

  def status_should_be_given?
    return false if vaccinated?

    consents_for_status.any? && consents_for_status.all?(&:response_given?) &&
      agreed_vaccine_methods.present?
  end

  def status_should_be_refused?
    return false if vaccinated?

    latest_consents.any? && latest_consents.all?(&:response_refused?)
  end

  def status_should_be_conflicts?
    return false if vaccinated?

    consents_for_status =
      (self_consents.any? ? self_consents : parental_consents)

    if consents_for_status.any?(&:response_refused?) &&
         consents_for_status.any?(&:response_given?)
      return true
    end

    consents_for_status.any? && consents_for_status.all?(&:response_given?) &&
      agreed_vaccine_methods.blank?
  end

  def status_should_be_no_response? = !vaccinated?

  def agreed_vaccine_methods
    @agreed_vaccine_methods ||=
      consents_for_status.map(&:vaccine_methods).inject(&:intersection)
  end

  def consents_for_status
    @consents_for_status ||=
      self_consents.any? ? self_consents : parental_consents
  end

  def self_consents
    @self_consents ||= latest_consents.select(&:via_self_consent?)
  end

  def parental_consents
    @parental_consents ||= latest_consents.reject(&:via_self_consent?)
  end

  def latest_consents
    @latest_consents ||=
      ConsentGrouper.call(consents, programme_id: programme.id, academic_year:)
  end
end
