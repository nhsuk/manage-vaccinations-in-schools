# frozen_string_literal: true

class DPSExportRow
  FIELDS = [
    "nhs_number", #                       0
    "person_forename", #                  1
    "person_surname", #                   2
    "person_dob", #                       3
    "person_gender_code", #               4
    "person_postcode", #                  5
    "date_and_time", #                    6
    "site_code", #                        7
    "site_code_type_uri", #               8
    "unique_id", #                        9
    "unique_id_uri", #                    10
    "action_flag", #                      11
    "performing_professional_forename", # 12
    "performing_professional_surname", #  13
    "recorded_date", #                    14
    "primary_source", #                   15
    "vaccination_procedure_code", #       16
    "vaccination_procedure_term", #       17
    "dose_sequence", #                    18
    "vaccine_product_code", #             19
    "vaccine_product_term", #             20
    "vaccine_manufacturer", #             21
    "batch_number", #                     22
    "expiry_date", #                      23
    "site_of_vaccination_code", #         24
    "site_of_vaccination_term", #         25
    "route_of_vaccination_code", #        26
    "route_of_vaccination_term", #        27
    "dose_amount", #                      28
    "dose_unit_code", #                   29
    "dose_unit_term", #                   30
    "indication_code", #                  31
    "location_code", #                    32
    "location_code_type_uri" #            33
  ].freeze

  def initialize(vaccination_record)
    @vaccination_record = vaccination_record
  end

  def to_a
    FIELDS.map { send _1 }
  end

  private

  attr_reader :vaccination_record

  delegate :batch,
           :campaign,
           :delivery_site,
           :location,
           :patient,
           :user,
           :vaccine,
           to: :vaccination_record

  def nhs_number
    patient.nhs_number
  end

  def person_forename
    patient.first_name
  end

  def person_surname
    patient.last_name
  end

  def person_dob
    patient.date_of_birth.to_fs(:dps)
  end

  def person_gender_code
    patient.gender_code_before_type_cast
  end

  def person_postcode
    patient.address_postcode
  end

  def date_and_time
    vaccination_record.recorded_at.strftime("%Y%m%dT%H%M%S00")
  end

  def site_code
    campaign.team.ods_code
  end

  def site_code_type_uri
    "https://fhir.nhs.uk/Id/ods-organization-code"
  end

  def unique_id
  end

  def unique_id_uri
  end

  def action_flag
    "new"
  end

  def performing_professional_forename
    user&.full_name&.split(" ", 2)&.first
  end

  def performing_professional_surname
    user&.full_name&.split(" ", 2)&.last
  end

  def recorded_date
    vaccination_record.created_at.to_date.to_fs(:dps)
  end

  def primary_source
    "FALSE"
  end

  def vaccination_procedure_code
    vaccine.snomed_procedure_code_and_term.first
  end

  def vaccination_procedure_term
    vaccine.snomed_procedure_code_and_term.last
  end

  def dose_sequence
  end

  def vaccine_product_code
    vaccine.snomed_product_code
  end

  def vaccine_product_term
    vaccine.snomed_product_term
  end

  def vaccine_manufacturer
    vaccine.supplier
  end

  def batch_number
    batch.name
  end

  def expiry_date
    vaccination_record.batch.expiry.to_fs(:dps)
  end

  def route_of_vaccination_code
    VaccinationRecord::DELIVERY_METHOD_SNOMED_CODES_AND_TERMS[
      vaccination_record.delivery_method
    ].first
  end

  def route_of_vaccination_term
    VaccinationRecord::DELIVERY_METHOD_SNOMED_CODES_AND_TERMS[
      vaccination_record.delivery_method
    ].last
  end

  def dose_amount
    vaccination_record.dose
  end

  def dose_unit_code
    "258773002" # the SCTID for Milliliter (qualifier value)
  end

  def dose_unit_term
    "Milliliter (qualifier value)"
  end

  def indication_code
    # is not required if PRIMARY_SOURCE is FALSE
  end

  def location_code
    location&.urn.presence || campaign.team.ods_code
  end

  def location_code_type_uri
    if location&.urn.present?
      "https://fhir.hl7.org.uk/Id/urn-school-number"
    else
      "https://fhir.nhs.uk/Id/ods-organization-code"
    end
  end

  def site_of_vaccination_code
    VaccinationRecord::DELIVERY_SITE_SNOMED_CODES_AND_TERMS[
      vaccination_record.delivery_site
    ].first
  end

  def site_of_vaccination_term
    VaccinationRecord::DELIVERY_SITE_SNOMED_CODES_AND_TERMS[
      vaccination_record.delivery_site
    ].last
  end
end
