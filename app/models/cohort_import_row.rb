# frozen_string_literal: true

class CohortImportRow < PatientImportRow
  SCHOOL_URN_HOME_EDUCATED = "999999"
  SCHOOL_URN_UNKNOWN = "888888"

  validate :school_urn_inclusion

  def initialize(data:, team:, programme:)
    super(data:, team:, year_groups: programme.year_groups)
  end

  def school_urn
    @data["CHILD_SCHOOL_URN"]&.strip
  end

  private

  def school
    @school ||=
      unless [SCHOOL_URN_HOME_EDUCATED, SCHOOL_URN_UNKNOWN].include?(school_urn)
        Location.school.find_by!(urn: school_urn)
      end
  end

  def home_educated
    if school_urn == SCHOOL_URN_UNKNOWN
      nil
    else
      school_urn == SCHOOL_URN_HOME_EDUCATED
    end
  end

  def school_urn_inclusion
    unless Location.school.exists?(urn: school_urn) ||
             school_urn.in?([SCHOOL_URN_HOME_EDUCATED, SCHOOL_URN_UNKNOWN])
      errors.add(:school_urn, :inclusion)
    end
  end
end
