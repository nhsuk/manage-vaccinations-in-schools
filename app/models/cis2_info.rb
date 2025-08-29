# frozen_string_literal: true

class CIS2Info
  include RequestSessionPersistable

  NURSE_ROLE = "S8000:G8000:R8001"
  ADMIN_ROLE = "S8000:G8001:R8006"

  SUPERUSER_WORKGROUP = "mavissuperusers"

  PERSONAL_MEDICATION_ADMINISTRATION_ACTIVITY_CODE = "B0428"

  attribute :organisation_name
  attribute :organisation_code
  attribute :role_name
  attribute :role_code
  attribute :activity_codes, array: true
  attribute :workgroups, array: true
  attribute :team_workgroup
  attribute :has_other_roles, :boolean

  def present? = attributes.compact_blank.present?

  def organisation
    @organisation ||=
      if (ods_code = organisation_code).present?
        Organisation.find_by(ods_code:)
      end
  end

  def team
    @team ||=
      if (workgroup = team_workgroup).present? && workgroups.include?(workgroup)
        Team.find_by(organisation:, workgroup:)
      end
  end

  def has_valid_workgroup? =
    organisation&.teams&.exists?(workgroup: workgroups) || false

  def is_admin?
    role_code == ADMIN_ROLE
  end

  def is_nurse?
    role_code == NURSE_ROLE
  end

  def is_healthcare_assistant?
    activity_codes.include?(PERSONAL_MEDICATION_ADMINISTRATION_ACTIVITY_CODE)
  end

  def is_superuser?
    workgroups.include?(SUPERUSER_WORKGROUP)
  end

  private

  def request_session_key = "cis2_info"
end
