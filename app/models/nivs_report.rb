# frozen_string_literal: true

require "csv"

class NivsReport
  HEADERS = %w[
    ORGANISATION_CODE
    SCHOOL_URN
    SCHOOL_NAME
    NHS_NUMBER
    PERSON_FORENAME
    PERSON_SURNAME
    PERSON_DOB
    PERSON_GENDER_CODE
    PERSON_POSTCODE
    DATE_OF_VACCINATION
    VACCINE_GIVEN
    BATCH_NUMBER
    BATCH_EXPIRY_DATE
    ANATOMICAL_SITE
    DOSE_SEQUENCE
    LOCAL_PATIENT_ID
    LOCAL_PATIENT_ID_URI
    CARE_SETTING
  ].freeze

  def initialize(vaccination_records)
    @vaccination_records = vaccination_records
  end

  def to_csv
    CSV.generate(headers: true, force_quotes: true) do |csv|
      csv << HEADERS
      @vaccination_records.each { csv << Row.new(_1).to_a }
    end
  end

  class Row
    def initialize(vaccination_record)
      @vaccination_record = vaccination_record
    end

    attr_reader :vaccination_record

    delegate :campaign, :patient, :session, :batch, to: :vaccination_record

    def to_a
      [
        campaign.team.ods_code,
        session.location.urn,
        session.location.name,
        patient.nhs_number,
        patient.first_name,
        patient.last_name,
        patient.date_of_birth.to_fs(:number),
        "Not Known", # gender code not available
        patient.address_postcode,
        vaccination_record.recorded_at.to_date.to_fs(:number),
        batch.vaccine.brand,
        batch.name,
        batch.expiry.to_fs(:number),
        delivery_site,
        "1", # dose sequence hard-coded to 1 for HPV
        "MAVIS-#{patient.id}",
        "", # LOCAL_PATIENT_ID_URI
        "1 - School"
      ]
    end

    private

    SITE_MAPPING = {
      "left_arm_upper_position" => "Left Upper Arm",
      "right_arm_upper_position" => "Right Upper Arm",
      "left_arm_lower_position" => "Left Upper Arm", # NIVS doesn't support lower positions
      "right_arm_lower_position" => "Right Upper Arm", # NIVS doesn't support lower positions
      "left_thigh" => "Left Thigh",
      "right_thigh" => "Right Thigh"
    }.freeze

    def delivery_site
      return "Nasal" if batch.vaccine.nasal?

      SITE_MAPPING[vaccination_record.delivery_site]
    end
  end
end
