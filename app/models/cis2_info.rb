# frozen_string_literal: true

class CIS2Info
  include RequestSessionPersistable

  NURSE_ROLE = "S8000:G8000:R8001"
  ADMIN_ROLE = "S8000:G8001:R8006"

  WORKGROUP = "schoolagedimmunisations"
  SUPERUSER_WORKGROUP = "mavissuperusers"

  attribute :organisation_name
  attribute :organisation_code
  attribute :role_name
  attribute :role_code
  attribute :workgroups, array: true
  attribute :has_other_roles, :boolean

  def present? = attributes.compact_blank.present?

  def organisation
    @organisation ||=
      if (ods_code = organisation_code).present?
        Organisation.find_by(ods_code:)
      end
  end

  def has_workgroup? = workgroups&.include?(WORKGROUP) || false

  def is_admin? = role_code == ADMIN_ROLE

  def is_nurse? = role_code == NURSE_ROLE

  def is_superuser? = workgroups&.include?(SUPERUSER_WORKGROUP) || false

  # TODO: How do we determine this from CIS2?
  def is_healthcare_assistant? = false

  private

  def request_session_key = "cis2_info"

  def reset_unused_fields
  end
end
