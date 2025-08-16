# frozen_string_literal: true

module ImportsHelper
  FIELD_GROUPS = {
    %w[address_line_1 address_line_2 address_town address_postcode] => :address,
    %w[date_of_birth] => :date_of_birth,
    %w[nhs_number] => :nhs_number,
    %w[gender_code] => :gender,
    %w[given_name family_name preferred_given_name preferred_family_name] =>
      :name,
    %w[birth_academic_year] => :year_group,
    %w[registration] => :registration
  }.freeze

  def import_issues_count
    vaccination_records_with_issues =
      policy_scope(VaccinationRecord).with_pending_changes.distinct.pluck(
        :patient_id
      )

    patients_with_issues = policy_scope(Patient).with_pending_changes.pluck(:id)

    (vaccination_records_with_issues + patients_with_issues).uniq.length
  end

  def issue_categories_for(pending_changes)
    FIELD_GROUPS.filter_map do |(keys, group)|
      group.to_s.humanize if (pending_changes & keys).any?
    end
  end
end
