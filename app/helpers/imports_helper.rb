# frozen_string_literal: true

module ImportsHelper
  def import_issues_count
    vaccination_records_with_issues =
      policy_scope(VaccinationRecord).with_pending_changes.distinct.pluck(
        :patient_id
      )

    patients_with_issues = policy_scope(Patient).with_pending_changes.pluck(:id)

    (vaccination_records_with_issues + patients_with_issues).uniq.length
  end
end
