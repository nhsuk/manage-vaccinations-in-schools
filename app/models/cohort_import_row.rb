# frozen_string_literal: true

class CohortImportRow < PatientImportRow
  validates :address_postcode, postcode: true

  SCHOOL_URN_HOME_EDUCATED = "999999"
  SCHOOL_URN_UNKNOWN = "888888"

  validate :school_urn_inclusion

  def initialize(data:, organisation:)
    super(data:, organisation:, year_groups: organisation.year_groups)
  end

  def school_urn
    @data["CHILD_SCHOOL_URN"]&.strip
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

  def school_urn_inclusion
    unless Location.school.exists?(urn: school_urn) ||
             school_urn.in?([SCHOOL_URN_HOME_EDUCATED, SCHOOL_URN_UNKNOWN])
      errors.add(:school_urn, :inclusion)
    end
  end
end
