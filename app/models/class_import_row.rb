# frozen_string_literal: true

class ClassImportRow < PatientImportRow
  validate :validate_address_postcode

  def initialize(data:, team:, academic_year:, location:, year_groups:)
    super(data:, team:, academic_year:, year_groups:)
    @school = location
  end

  attr_reader :school

  def school_move_source
    :class_list_import
  end

  def home_educated
    nil # false is used when school is unknown
  end

  private

  def stage_registration?
    false
  end

  def validate_existing_patients
    matches = existing_patients

    return if matches.nil? || matches.length <= 1

    return if allow_twin_like_matches?(matches)

    errors.add(
      :base,
      "More than one possible patient matches the patient first name, last name, date of birth and postcode."
    )
  end

  def allow_twin_like_matches?(matches)
    # We only bypass the hard stop when there isn't more than one exact match
    # on all attributes; exact duplicates should be blocked for review.
    exact_matches =
      matches.select do |patient|
        patient.given_name.to_s.casecmp?(first_name.to_s) &&
          patient.family_name.to_s.casecmp?(last_name.to_s) &&
          patient.date_of_birth == date_of_birth.to_date &&
          patient.address_postcode == address_postcode&.to_postcode&.to_s
      end

    return false if exact_matches.length > 1

    matches.all? do |patient|
      patient.family_name.to_s.casecmp?(last_name.to_s) &&
        patient.date_of_birth == date_of_birth.to_date &&
        patient.address_postcode == address_postcode&.to_postcode&.to_s
    end
  end

  def validate_address_postcode
    if address_postcode.present? && address_postcode.to_postcode.nil?
      errors.add(address_postcode.header, "should be a postcode, like SW1A 1AA")
    end
  end
end
