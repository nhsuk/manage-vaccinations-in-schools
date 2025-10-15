# frozen_string_literal: true

class StatusGenerator::Vaccination
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
    if status_should_be_vaccinated?
      :vaccinated
    elsif status_should_be_could_not_vaccinate?
      :could_not_vaccinate
    else
      :none_yet
    end
  end

  def location_id
    vaccination_record&.location_id if status_should_be_vaccinated?
  end

  private

  attr_reader :programme,
              :academic_year,
              :patient,
              :consents,
              :triages,
              :vaccination_records

  def programme_id = programme.id

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

  def status_should_be_vaccinated?
    vaccination_record != nil
  end

  def status_should_be_could_not_vaccinate?
    if ConsentGrouper.call(consents, programme_id:, academic_year:).any?(
         &:response_refused?
       )
      return true
    end

    TriageFinder.call(triages, programme_id:, academic_year:)&.do_not_vaccinate?
  end
end
