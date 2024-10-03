# frozen_string_literal: true

class CohortImportRow < PatientImportRow
  SCHOOL_URN_HOME_EDUCATED = "999999"
  SCHOOL_URN_UNKNOWN = "888888"

  validates :school_urn,
            inclusion: {
              in: -> do
                Location.school.pluck(:urn) +
                  [SCHOOL_URN_HOME_EDUCATED, SCHOOL_URN_UNKNOWN]
              end
            }

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
end
