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
    vaccination.patient.date_of_birth
  end

  def person_gender_code
    vaccination.patient.gender_code_before_type_cast
  end

  def person_postcode
    vaccination.patient.address_postcode
  end

  def date_and_time
    vaccination.recorded_at
  end
end
