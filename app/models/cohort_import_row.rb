# frozen_string_literal: true

class CohortImportRow < PatientImportRow
  validate :validate_address_postcode, :validate_school_urn

  SCHOOL_URN_HOME_EDUCATED = "999999"
  SCHOOL_URN_UNKNOWN = "888888"

  def initialize(data:, organisation:)
    super(data:, organisation:, year_groups: organisation.year_groups)
  end

  def school_urn
    @data[:child_school_urn]&.to_s
  end

  private

  def stage_registration?
    true
  end

  def school_move_source
    :cohort_import
  end

  def school
    @school ||=
      unless [SCHOOL_URN_HOME_EDUCATED, SCHOOL_URN_UNKNOWN].include?(school_urn)
        Location.school.find_by!(urn: school_urn)
      end
  end

  def home_educated
    if school_urn == SCHOOL_URN_HOME_EDUCATED
      true
    elsif school_urn == SCHOOL_URN_UNKNOWN
      false
    end
  end

  def validate_address_postcode
    if address_postcode.nil?
      errors.add(:base, "<code>CHILD_POSTCODE</code> is missing")
    elsif address_postcode.blank?
      errors.add(address_postcode.header, "is required but missing")
    elsif address_postcode.to_postcode.nil?
      errors.add(address_postcode.header, "should be a postcode, like SW1A 1AA")
    end
  end

  def validate_school_urn
    unless Location.school.exists?(urn: school_urn) ||
             school_urn.in?([SCHOOL_URN_HOME_EDUCATED, SCHOOL_URN_UNKNOWN])
      errors.add(:school_urn, :inclusion)
    end
  end
end
