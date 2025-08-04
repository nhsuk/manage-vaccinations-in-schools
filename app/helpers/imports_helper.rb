# frozen_string_literal: true

module ImportsHelper
  def import_issues_count
    vaccination_records_with_issues =
      policy_scope(VaccinationRecord).with_pending_changes.distinct

    patients_with_issues = policy_scope(Patient).with_pending_changes

    unique_import_issues =
      (vaccination_records_with_issues + patients_with_issues).uniq do |record|
        record.is_a?(VaccinationRecord) ? record.patient_id : record.id
      end

    unique_import_issues.count
  end
end
