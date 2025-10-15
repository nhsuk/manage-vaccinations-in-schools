# frozen_string_literal: true

class StatusGenerator::Vaccination
  def initialize(
    programme:,
    academic_year:,
    patient:,
    patient_locations:,
    consents:,
    triages:,
    vaccination_records:
  )
    @programme = programme
    @academic_year = academic_year
    @patient = patient
    @patient_locations = patient_locations
    @consents = consents
    @triages = triages
    @vaccination_records = vaccination_records
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

  def location_id
    vaccination_record&.location_id if status_should_be_vaccinated?
  end

  private

  attr_reader :programme,
              :academic_year,
              :patient,
              :patient_locations,
              :consents,
              :triages,
              :vaccination_records

  def programme_id = programme.id

  def year_group = patient.year_group(academic_year:)

  def relevant_vaccination_records
    @relevant_vaccination_records ||=
      vaccination_records.select do
        it.patient_id == patient.id && it.programme_id == programme_id &&
          if programme.seasonal?
            it.academic_year == academic_year
          else
            it.academic_year <= academic_year
          end
      end
  end

  def vaccination_record
    if programme.seasonal?
      relevant_vaccination_records.find { it.administered? || it.already_had? }
    elsif programme.mmr?
      nil # TODO: Implement vaccination criteria
    else
      if (
           already_had_record =
             relevant_vaccination_records.find(&:already_had?)
         )
        return already_had_record
      end

      administered_records =
        relevant_vaccination_records.select(&:administered?)

      if programme.hpv?
        administered_records.first
      elsif programme.menacwy?
        administered_records.find { patient.age(now: it.performed_at) >= 10 }
      elsif programme.td_ipv?
        administered_records.find do
          (
            it.dose_sequence == programme.vaccinated_dose_sequence ||
              (it.dose_sequence.nil? && it.recorded_in_service?)
          ) && patient.age(now: it.performed_at) >= 10
        end
      else
        raise UnsupportedProgramme, programme
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

  def status_should_be_vaccinated?
    vaccination_record != nil
  end

  def status_should_be_due?
    return false unless is_eligible?

    return false unless consent_generator.status == :given

    triage_generator.status.in?(%i[safe_to_vaccinate not_required])
  end

  def status_should_be_eligible? = is_eligible?
end
