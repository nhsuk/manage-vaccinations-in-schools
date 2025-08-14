# frozen_string_literal: true

class CohortImportRow < PatientImportRow
  validate :validate_address_postcode, :validate_school_urn

  SCHOOL_URN_HOME_EDUCATED = "999999"
  SCHOOL_URN_UNKNOWN = "888888"

  def initialize(data:, team:, academic_year:)
    super(data:, team:, academic_year:, year_groups: team.year_groups)
  end

  def school_urn = @data[:child_school_urn]

  def school_move_source
    :cohort_import
  end

  def school
    @school ||=
      if (urn = school_urn&.to_s).present? &&
           ![SCHOOL_URN_HOME_EDUCATED, SCHOOL_URN_UNKNOWN].include?(urn)
        Location.school.find_by!(urn:)
      end
  end

  def home_educated
    if school_urn&.to_s == SCHOOL_URN_HOME_EDUCATED
      true
    elsif school_urn&.to_s == SCHOOL_URN_UNKNOWN
      false
    end
  end

  private

  def stage_registration?
    true
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
    if school_urn.nil?
      errors.add(:base, "<code>CHILD_SCHOOL_URN</code> is missing")
    elsif school_urn.blank?
      errors.add(school_urn.header, "is required but missing")
    elsif !Location.school.exists?(urn: school_urn.to_s) &&
          !school_urn.to_s.in?([SCHOOL_URN_HOME_EDUCATED, SCHOOL_URN_UNKNOWN])
      errors.add(
        school_urn.header,
        "The school URN is not recognised. If you’ve checked the URN, " \
          "and you believe it’s valid, contact our support team."
      )
    end
  end
end
