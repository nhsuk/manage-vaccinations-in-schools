# frozen_string_literal: true

class CIS2Info
  include RequestSessionPersistable

  NURSE_ROLE = "S8000:G8000:R8001"
  ADMIN_ROLE = "S8000:G8001:R8006"

  SUPERUSER_WORKGROUP = "mavissuperusers"

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

  def can_view?
    [ADMIN_ROLE, NURSE_ROLE].include?(role_code)
  end

  def can_supply_using_pgd?
    role_code == NURSE_ROLE
  end

  def can_perform_local_admin_tasks?
    in_superuser_workgroup?
  end

  def can_access_sensitive_records?
    in_superuser_workgroup?
  end

  private

  def request_session_key = "cis2_info"

  def in_superuser_workgroup? = workgroups.include?(SUPERUSER_WORKGROUP)
end
