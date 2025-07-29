# frozen_string_literal: true

class CIS2Info
  include RequestSessionPersistable

  NURSE_ROLE = "S8000:G8000:R8001"
  ADMIN_ROLE = "S8000:G8001:R8006"
  SUPPORT_ROLE = "S8001:G8005:R8015"

  SUPERUSER_WORKGROUP = "mavissuperusers"
  SUPPORT_WORKGROUP = "mavissupport"

  SUPPORT_ORGANISATION = "X26"

  SUPPORT_ACTIVITIES = %w[D0008:C0055:B1611 D8002:C8006:B0360].freeze

  attribute :organisation_name
  attribute :organisation_code
  attribute :role_name
  attribute :role_code
  attribute :workgroups, array: true
  attribute :team_workgroup
  attribute :activity_codes, array: true
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
      if (workgroup = team_workgroup).present? &&
           workgroups&.include?(workgroup)
        Team.find_by(organisation:, workgroup:)
      end
  end

  def has_valid_workgroup? =
    organisation&.teams&.exists?(workgroup: workgroups) || false

  def is_admin? = role_code == ADMIN_ROLE

  def is_nurse? = role_code == NURSE_ROLE

  def is_superuser? = workgroups&.include?(SUPERUSER_WORKGROUP) || false

  # TODO: How do we determine this from CIS2?
  def is_healthcare_assistant? = false

  def is_support?
    (
      workgroups&.include?(SUPPORT_WORKGROUP) && role_code == SUPPORT_ROLE &&
        organisation_code == SUPPORT_ORGANISATION &&
        (SUPPORT_ACTIVITIES - activity_codes).empty?
    ) || false
  end

  private

  def request_session_key = "cis2_info"

  def reset_unused_fields
  end
end
