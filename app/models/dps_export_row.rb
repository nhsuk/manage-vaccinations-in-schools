# frozen_string_literal: true

class DPSExportRow
  FIELDS = %i[
    nhs_number
    person_forename
    person_surname
    person_dob
    person_gender_code
    person_postcode
    date_and_time
    recorded_date
    site_of_vaccination_code
    site_of_vaccination_term
  ].freeze

  attr_reader :vaccination

  def initialize(vaccination)
    @vaccination = vaccination
  end

  def to_a
    FIELDS.map { send _1 }
  end

  private

  def nhs_number
    vaccination.patient.nhs_number
  end

  def person_forename
    vaccination.patient.first_name
  end

  def person_surname
    vaccination.patient.last_name
  end

  def person_dob
    vaccination.patient.date_of_birth.strftime("%Y%m%d")
  end

  def person_gender_code
    vaccination.patient.gender_code_before_type_cast
  end

  def person_postcode
    vaccination.patient.address_postcode
  end

  def date_and_time
    vaccination.recorded_at.strftime("%Y%m%dT%H%M%S00")
  end

  def recorded_date
    vaccination.created_at.strftime("%Y%m%d")
  end

  def site_of_vaccination_code
    VaccinationRecord::DELIVERY_SITE_SNOMED_CODES_AND_TERMS[
      vaccination.delivery_site
    ].first
  end

  def site_of_vaccination_term
    VaccinationRecord::DELIVERY_SITE_SNOMED_CODES_AND_TERMS[
      vaccination.delivery_site
    ].last
  end
end
