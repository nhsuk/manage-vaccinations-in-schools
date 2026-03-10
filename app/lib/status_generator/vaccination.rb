# frozen_string_literal: true

class StatusGenerator::Vaccination
  ##
  # Creates a new instance of the status generator used to determine the
  # vaccination status of a patient.
  #
  # The `consents`, `triages` and `vaccination_records` arguments are expected
  # to already be sorted in reverse chronological order, meaning the most
  # recent item is at the beginning of the array.
  def initialize(
    programme_type:,
    academic_year:,
    patient:,
    patient_locations:,
    consents:,
    triages:,
    attendance_record:,
    vaccination_records:
  )
    @programme_type = programme_type
    @academic_year = academic_year
    @patient = patient
    @patient_locations = patient_locations
    @consents = consents
    @triages = triages
    @attendance_record = attendance_record

    @vaccination_criteria =
      VaccinationCriteria.new(
        programme_type:,
        academic_year:,
        patient:,
        vaccination_records:
      )
  end

  def programme
    Programme.find(programme_type, disease_types:, patient:)
  end

  def status
    if status_should_be_vaccinated?
      :vaccinated
    elsif status_should_be_due?
      :due
    elsif status_should_be_eligible?
      :eligible
    else
      :not_eligible
    end
  end

  def disease_types
    vaccinated_vaccination_record.disease_types if status_should_be_vaccinated?
  end

  def dose_sequence
    return unless status_should_be_due? || status_should_be_eligible?

    # Patients receive dose 5 of Td/IPV by default, regardless of vaccination history
    return 5 if programme.td_ipv?

    valid_vaccination_records.count + 1
  end

  def latest_date
    if status_should_be_vaccinated?
      vaccinated_vaccination_record.performed_at_date
    elsif latest_session_status_should_be_absent?
      attendance_record.date
    else
      vaccination_records.map(&:performed_at_date).max
    end
  end

  def latest_location_id
    vaccinated_vaccination_record&.location_id if status_should_be_vaccinated?
  end

  def latest_session_status
    if status_should_be_vaccinated?
      :already_had if latest_session_status_should_be_already_had?
    elsif status_should_be_due? || status_should_be_eligible?
      if latest_session_status_should_be_contraindicated?
        :contraindicated
      elsif latest_session_status_should_be_refused?
        :refused
      elsif latest_session_status_should_be_absent?
        :absent
      elsif latest_session_status_should_be_unwell?
        :unwell
      end
    end
  end

  private

  attr_reader :programme_type,
              :academic_year,
              :patient,
              :patient_locations,
              :consents,
              :triages,
              :attendance_record,
              :vaccination_criteria

  delegate :vaccinated_vaccination_record,
           :valid_vaccination_records,
           :vaccination_records,
           to: :vaccination_criteria

  def status_should_be_vaccinated?
    vaccinated_vaccination_record != nil
  end

  def status_should_be_due?
    return false unless is_eligible?

    return false unless consent_generator.status == :given

    triage_generator.status.in?(%i[safe_to_vaccinate not_required])
  end

  def status_should_be_eligible? = is_eligible?

  def latest_session_status_should_be_contraindicated?
    vaccination_records.first&.contraindicated?
  end

  def latest_session_status_should_be_refused?
    vaccination_records.first&.refused?
  end

  def latest_session_status_should_be_absent?
    attendance_record&.attending == false
  end

  def latest_session_status_should_be_unwell?
    vaccination_records.first&.unwell?
  end

  def latest_session_status_should_be_already_had?
    vaccinated_vaccination_record&.already_had?
  end

  def year_group = patient.year_group(academic_year:)

  def is_eligible?
    @is_eligible ||=
      patient_locations
        .select { it.academic_year == academic_year }
        .any? do |patient_location|
          patient_location.location.location_programme_year_groups.any? do
            it.programme_type == programme_type &&
              it.academic_year == academic_year && it.year_group == year_group
          end
        end
  end

  def consent_generator
    @consent_generator ||=
      StatusGenerator::Consent.new(
        programme_type:,
        academic_year:,
        patient:,
        consents:,
        vaccination_records:
      )
  end

  def triage_generator
    @triage_generator ||=
      StatusGenerator::Triage.new(
        programme_type:,
        academic_year:,
        patient:,
        consents:,
        triages:,
        vaccination_records:
      )
  end
end
