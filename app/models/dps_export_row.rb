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
    site_code
    site_code_type_uri
    unique_id
    unique_id_uri
    action_flag
    performing_professional_forename
    performing_professional_surname
    recorded_date
    primary_source
    vaccination_procedure_code
    vaccination_procedure_term
    dose_sequence
    vaccine_product_code
    vaccine_product_term
    vaccine_manufacturer
    batch_number
    expiry_date
    site_of_vaccination_code
    site_of_vaccination_term
    route_of_vaccination_code
    route_of_vaccination_term
    dose_amount
    dose_unit_code
    dose_unit_term
    indication_code
    location_code
    location_code_type_uri
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

  def site_code
    vaccination.campaign.team.ods_code
  end

  def site_code_type_uri
    "https://fhir.nhs.uk/Id/ods-organization-code"
  end

  def unique_id
  end

  def unique_id_uri
  end

  def action_flag
  end

  def performing_professional_forename
    vaccination&.user&.full_name&.split(" ", 2)&.first
  end

  def performing_professional_surname
    vaccination&.user&.full_name&.split(" ", 2)&.last
  end

  def recorded_date
    vaccination.created_at.strftime("%Y%m%d")
  end

  def primary_source
  end

  def vaccination_procedure_code
  end

  def vaccination_procedure_term
  end

  def dose_sequence
  end

  def vaccine_product_code
  end

  def vaccine_product_term
  end

  def vaccine_manufacturer
  end

  def batch_number
  end

  def expiry_date
  end

  def route_of_vaccination_code
  end

  def route_of_vaccination_term
  end

  def dose_amount
    vaccination.dose
  end

  def dose_unit_code
    "258773002" # the SCTID for Milliliter (qualifier value)
  end

  def dose_unit_term
    "Milliliter (qualifier value)"
  end

  def indication_code
  end

  def location_code
  end

  def location_code_type_uri
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
