# frozen_string_literal: true

class StatusGenerator::Vaccination
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

    @vaccination_records =
      vaccination_records.select do
        it.patient_id == patient.id && it.programme_id == programme_id &&
          if programme.seasonal?
            it.academic_year == academic_year
          else
            it.academic_year <= academic_year
          end
      end
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

  def dose_sequence
    # TODO: Implement this for multi-dose HPV and Td/IPV in a more generic way.
    return unless programme.mmr?

    return unless status_should_be_due? || status_should_be_eligible?

    latest_dose_sequence =
      valid_vaccination_records.filter_map(&:dose_sequence).max || 0

    latest_dose_sequence + 1
  end

  def latest_date
    if status_should_be_vaccinated?
      vaccinated_vaccination_record.performed_at.to_date
    elsif latest_session_status_should_be_absent?
      [
        vaccination_records.map(&:performed_at).max&.to_date,
        attendance_record&.created_at&.to_date
      ].compact.max
    else
      vaccination_records.map(&:performed_at).max&.to_date
    end
  end

  def latest_location_id
    vaccinated_vaccination_record&.location_id if status_should_be_vaccinated?
  end

  def latest_session_status
    if status_should_be_due? || status_should_be_eligible?
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

  attr_reader :programme,
              :academic_year,
              :patient,
              :patient_locations,
              :consents,
              :triages,
              :attendance_record,
              :vaccination_records

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
    vaccination_records.last&.contraindications?
  end

  def latest_session_status_should_be_refused?
    vaccination_records.last&.refused?
  end

  def latest_session_status_should_be_absent?
    vaccination_records.last&.absent_from_session? ||
      attendance_record&.attending == false
  end

  def latest_session_status_should_be_unwell?
    vaccination_records.last&.not_well?
  end

  def programme_id = programme.id

  def year_group = patient.year_group(academic_year:)

  def valid_vaccination_records
    @valid_vaccination_records ||=
      if programme.seasonal?
        vaccination_records.select { it.administered? || it.already_had? }
      else
        if (
             already_had_records = vaccination_records.select(&:already_had?)
           ).present?
          return already_had_records
        end

        administered_records = vaccination_records.select(&:administered?)

        if programme.hpv?
          administered_records
        elsif programme.menacwy?
          administered_records.select do
            patient.age_years(now: it.performed_at) >= 10
          end
        elsif programme.mmr?
          administered_records # TODO: Implement vaccination criteria
        elsif programme.td_ipv?
          administered_records.select do
            patient.age_years(now: it.performed_at) >= 10
          end
        else
          raise UnsupportedProgramme, programme
        end
      end
  end

  def vaccinated_vaccination_record
    @vaccinated_vaccination_record ||=
      begin
        if (already_had_record = valid_vaccination_records.find(&:already_had?))
          return already_had_record
        end

        if programme.td_ipv?
          valid_vaccination_records.find do
            it.dose_sequence == 5 ||
              (it.dose_sequence.nil? && it.recorded_in_service?)
          end
        else
          valid_vaccination_records.first
        end
      end
  end

  def is_eligible?
    @is_eligible ||=
      patient_locations
        .select { it.academic_year == academic_year }
        .any? do |patient_location|
          location = patient_location.location
          year_group.in?(
            location.programme_year_groups(academic_year:)[programme]
          )
        end
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
end
