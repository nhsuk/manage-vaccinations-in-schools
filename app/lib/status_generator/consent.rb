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

  def date
    consents_for_status.map(&:submitted_at).max.to_date
  end

  def vaccine_methods
    status_should_be_given? ? agreed_vaccine_methods : []
  end

  def without_gelatine
    status_should_be_given? ? agreed_without_gelatine : nil
  end

  private

  attr_reader :programme,
              :academic_year,
              :patient,
              :consents,
              :vaccination_records

  def vaccinated?
    # We only care about whether the patient is vaccinated so although we're
    # using the same status generator logic as elsewhere we don't need to pass
    # in the consents and triage as an optimisation.
    @vaccinated ||=
      StatusGenerator::Vaccination.new(
        programme:,
        academic_year:,
        patient:,
        vaccination_records:,
        patient_locations: [],
        triages: [],
        consents: [],
        attendance_record: nil
      ).status == :vaccinated
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

  def agreed_without_gelatine
    @agreed_without_gelatine ||= consents_for_status.any?(&:without_gelatine)
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
      ConsentGrouper.call(
        consents,
        programme_type: programme.type,
        academic_year:
      )
  end
end
