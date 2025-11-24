# frozen_string_literal: true

class StatusGenerator::Triage
  def initialize(
    programme:,
    academic_year:,
    patient:,
    consents:,
    triages:,
    vaccination_records:
  )
    @programme = programme
    @academic_year = academic_year
    @patient = patient
    @consents = consents
    @triages = triages
    @vaccination_records = vaccination_records
  end

  def status
    if status_should_be_safe_to_vaccinate?
      :safe_to_vaccinate
    elsif status_should_be_do_not_vaccinate?
      :do_not_vaccinate
    elsif status_should_be_delay_vaccination?
      :delay_vaccination
    elsif status_should_be_invite_to_clinic?
      :invite_to_clinic
    elsif status_should_be_required?
      :required
    else
      :not_required
    end
  end

  def vaccine_method
    latest_triage&.vaccine_method if status_should_be_safe_to_vaccinate?
  end

  def without_gelatine
    latest_triage&.without_gelatine if status_should_be_safe_to_vaccinate?
  end

  def consent_requires_triage?
    latest_consents.any?(&:requires_triage?)
  end

  def vaccination_history_requires_triage?
    return false unless programme.triage_on_vaccination_history?

    existing_records =
      vaccination_records.select { it.programme_type == programme_type }

    if programme.seasonal?
      existing_records.select! { it.academic_year == academic_year }
    end

    existing_records.any?(&:administered?) && !vaccinated?
  end

  private

  attr_reader :programme,
              :academic_year,
              :patient,
              :consents,
              :triages,
              :vaccination_records

  def programme_type = programme.type

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

  def status_should_be_safe_to_vaccinate?
    return false if vaccinated?
    latest_triage&.safe_to_vaccinate?
  end

  def status_should_be_do_not_vaccinate?
    return false if vaccinated?
    latest_triage&.do_not_vaccinate?
  end

  def status_should_be_delay_vaccination?
    return false if vaccinated?
    latest_triage&.delay_vaccination? && !latest_triage.expired?
  end

  def status_should_be_invite_to_clinic?
    return false if vaccinated?
    latest_triage&.invite_to_clinic?
  end

  def status_should_be_required?
    return false if vaccinated?
    return true if latest_triage&.keep_in_triage?
    return true if latest_triage&.expired?

    return false if latest_consents.empty?

    consent_generator.status == :given &&
      (consent_requires_triage? || vaccination_history_requires_triage?)
  end

  def consent_generator
    @consent_generator ||=
      StatusGenerator::Consent.new(
        programme:,
        academic_year:,
        patient:,
        consents:,
        vaccination_records:
      )
  end

  def latest_consents
    @latest_consents ||=
      ConsentGrouper.call(consents, programme_type:, academic_year:)
  end

  def latest_triage
    @latest_triage ||=
      TriageFinder.call(triages, programme_type:, academic_year:)
  end
end
