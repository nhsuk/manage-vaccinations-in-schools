# frozen_string_literal: true

class VaccinatedCriteria
  def initialize(programme:, academic_year:, patient:, vaccination_records:)
    @programme = programme
    @academic_year = academic_year
    @patient = patient
    @vaccination_records = vaccination_records
  end

  def vaccinated? = !vaccination_record.nil?

  delegate :location_id, to: :vaccination_record, allow_nil: true

  private

  attr_reader :programme, :academic_year, :patient, :vaccination_records

  def relevant_vaccination_records
    @relevant_vaccination_records ||=
      vaccination_records.select do
        it.patient_id == patient.id && it.programme_id == programme.id &&
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
end
