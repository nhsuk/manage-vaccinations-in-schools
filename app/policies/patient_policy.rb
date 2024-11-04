# frozen_string_literal: true

class PatientPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      cohort_ids = user.selected_organisation.cohorts.ids
      school_ids = user.selected_organisation.schools.ids

      scope
        .where(cohort_id: cohort_ids)
        .or(Patient.where(school_id: school_ids))
        .or(
          Patient.where(
            "pending_changes ->> 'cohort_id' != NULL AND pending_changes ->> 'cohort_id' IN (?)",
            cohort_ids
          )
        )
        .or(
          Patient.where(
            "pending_changes ->> 'school_id' != NULL AND pending_changes ->> 'school_id' IN (?)",
            school_ids
          )
        )
    end
  end
end
