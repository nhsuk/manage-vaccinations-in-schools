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
    @vaccination_records =
      vaccination_records.select { it.academic_year <= @academic_year }
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
    vaccinated_criteria.location_id if status_should_be_vaccinated?
  end

  private

  attr_reader :programme,
              :academic_year,
              :patient,
              :consents,
              :triages,
              :vaccination_records

  def programme_id = programme.id

  def vaccinated_criteria
    @vaccinated_criteria ||=
      VaccinatedCriteria.new(
        programme:,
        academic_year:,
        patient:,
        vaccination_records:
      )
  end

  def status_should_be_vaccinated?
    vaccinated_criteria.vaccinated?
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
