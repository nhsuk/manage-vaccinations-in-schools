# frozen_string_literal: true

class StatusGenerator::Programme
  ##
  # Creates a new instance of the status generator used to determine the
  # programme status of a patient.
  #
  # The `consents`, `triages` and `vaccination_records` arguments are expected
  # to already be sorted in reverse chronological order, meaning the most
  # recent item is at the beginning of the array.
  def initialize(
    programme:,
    academic_year:,
    patient:,
    patient_locations:,
    consents:,
    triages:,
    attendance_record:,
    vaccination_records:
  )
    @programme = programme
    @academic_year = academic_year
    @patient = patient
    @patient_locations = patient_locations
    @consents = consents
    @triages = triages
    @attendance_record = attendance_record
    @vaccination_records = vaccination_records
  end

  def status
    if should_be_vaccinated_already?
      :vaccinated_already
    elsif should_be_vaccinated_fully?
      :vaccinated_fully
    elsif should_be_cannot_vaccinate_unwell?
      :cannot_vaccinate_unwell
    elsif should_be_cannot_vaccinate_refused?
      :cannot_vaccinate_refused
    elsif should_be_cannot_vaccinate_contraindicated?
      :cannot_vaccinate_contraindicated
    elsif should_be_cannot_vaccinate_absent?
      :cannot_vaccinate_absent
    elsif should_be_cannot_vaccinate_delay_vaccination?
      :cannot_vaccinate_delay_vaccination
    elsif should_be_cannot_vaccinate_do_not_vaccinate?
      :cannot_vaccinate_do_not_vaccinate
    elsif should_be_due?
      :due
    elsif should_be_needs_triage?
      :needs_triage
    elsif should_be_has_refusal_consent_conflicts?
      :has_refusal_consent_conflicts
    elsif should_be_has_refusal_consent_refused?
      :has_refusal_consent_refused
    elsif should_be_needs_consent_follow_up_requested?
      :needs_consent_follow_up_requested
    elsif should_be_needs_consent_no_response?
      :needs_consent_no_response
    elsif should_be_needs_consent_request_failed?
      :needs_consent_request_failed
    elsif should_be_needs_consent_request_scheduled?
      :needs_consent_request_scheduled
    elsif should_be_needs_consent_request_not_scheduled?
      :needs_consent_request_not_scheduled
    else
      :not_eligible
    end
  end

  def dose_sequence
    if triage_generator.status.in?(%i[safe_to_vaccinate not_required]) &&
         consent_generator.status == :given
      vaccination_generator.dose_sequence
    end
  end

  def without_gelatine
    if vaccination_generator.status == :not_eligible ||
         triage_generator.status.in?(%i[required do_not_vaccinate]) ||
         consent_generator.status.in?(%i[no_response conflicts refused])
      return nil
    end

    triage_generator.without_gelatine || consent_generator.without_gelatine
  end

  def vaccine_methods
    if vaccination_generator.status == :not_eligible ||
         triage_generator.status.in?(%i[required do_not_vaccinate]) ||
         consent_generator.status.in?(%i[no_response conflicts refused])
      return nil
    end

    if triage_generator.vaccine_method
      [triage_generator.vaccine_method]
    else
      consent_generator.vaccine_methods
    end
  end

  def date
    triage_generator.delay_vaccination_until_date ||
      vaccination_generator.latest_date
  end

  private

  attr_reader :programme,
              :academic_year,
              :patient,
              :patient_locations,
              :consents,
              :triages,
              :attendance_record,
              :vaccination_records

  def should_be_vaccinated_already?
    vaccination_generator.status == :vaccinated &&
      vaccination_generator.latest_session_status == :already_had
  end

  def should_be_vaccinated_fully?
    vaccination_generator.status == :vaccinated
  end

  def should_be_cannot_vaccinate_unwell?
    vaccination_generator.status.in?(%i[eligible due]) &&
      vaccination_generator.latest_session_status == :unwell &&
      vaccination_generator.latest_date.today?
  end

  def should_be_cannot_vaccinate_refused?
    vaccination_generator.status.in?(%i[eligible due]) &&
      vaccination_generator.latest_session_status == :refused &&
      vaccination_generator.latest_date.today?
  end

  def should_be_cannot_vaccinate_contraindicated?
    vaccination_generator.status.in?(%i[eligible due]) &&
      vaccination_generator.latest_session_status == :contraindicated &&
      vaccination_generator.latest_date.today?
  end

  def should_be_cannot_vaccinate_absent?
    vaccination_generator.status.in?(%i[eligible due]) &&
      vaccination_generator.latest_session_status == :absent &&
      vaccination_generator.latest_date.today?
  end

  def should_be_cannot_vaccinate_delay_vaccination?
    vaccination_generator.status.in?(%i[eligible due]) &&
      triage_generator.status == :delay_vaccination
  end

  def should_be_cannot_vaccinate_do_not_vaccinate?
    vaccination_generator.status.in?(%i[eligible due]) &&
      triage_generator.status == :do_not_vaccinate
  end

  def should_be_due?
    vaccination_generator.status == :due
  end

  def should_be_needs_triage?
    triage_generator.status == :required
  end

  def should_be_has_refusal_consent_conflicts?
    consent_generator.status == :conflicts
  end

  def should_be_has_refusal_consent_refused?
    consent_generator.status == :refused
  end

  def should_be_needs_consent_follow_up_requested?
    false # TODO: Implement this status.
  end

  def should_be_needs_consent_no_response?
    vaccination_generator.status == :eligible &&
      consent_generator.status == :no_response
  end

  def should_be_needs_consent_request_failed?
    false # TODO: Implement this status.
  end

  def should_be_needs_consent_request_scheduled?
    false # TODO: Implement this status.
  end

  def should_be_needs_consent_request_not_scheduled?
    false # TODO: Implement this status.
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

  def triage_generator
    @triage_generator ||=
      StatusGenerator::Triage.new(
        programme:,
        academic_year:,
        patient:,
        consents:,
        triages:,
        vaccination_records:
      )
  end

  def vaccination_generator
    @vaccination_generator ||=
      StatusGenerator::Vaccination.new(
        programme:,
        academic_year:,
        patient:,
        patient_locations:,
        consents:,
        triages:,
        attendance_record:,
        vaccination_records:
      )
  end
end
