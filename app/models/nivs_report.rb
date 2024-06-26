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

  def initialize(vaccinations)
    @vaccinations = vaccinations
  end

  def to_csv
    CSV.generate(headers: true, force_quotes: true) do |csv|
      csv << HEADERS

      @vaccinations.each { csv << NivsReportRow.new(_1).to_a }
    end
  end
end
