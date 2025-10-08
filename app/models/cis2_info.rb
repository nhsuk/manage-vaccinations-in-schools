# frozen_string_literal: true

class CIS2Info
  include RequestSessionPersistable

  NURSE_ROLE = "S8000:G8000:R8001"
  MEDICAL_SECRETARY_ROLE = "S8000:G8001:R8006"
  SUPPORT_ROLE = "S8001:G8005:R8015"

  SUPPORT_WORKGROUP = "mavissupport"
  SUPPORT_ORGANISATION = "X26"

  ACCESS_SENSITIVE_FLAGGED_RECORDS_ACTIVITY_CODE = "B1611"
  INDEPENDENT_PRESCRIBING_ACTIVITY_CODE = "B0420"
  LOCAL_SYSTEM_ADMINISTRATION_ACTIVITY_CODE = "B0062"
  PERSONAL_MEDICATION_ADMINISTRATION_ACTIVITY_CODE = "B0428"
  VIEW_DETAILED_HEALTH_RECORDS_ACTIVITY_CODE = "B0360"
  VIEW_SHARED_NON_PATIENT_IDENTIFIABLE_INFORMATION_ACTIVITY_CODE = "B1570"

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

  def is_medical_secretary?
    role_code == MEDICAL_SECRETARY_ROLE
  end

  def is_nurse?
    role_code == NURSE_ROLE
  end

  def is_healthcare_assistant?
    role_code == MEDICAL_SECRETARY_ROLE &&
      activity_codes.include?(PERSONAL_MEDICATION_ADMINISTRATION_ACTIVITY_CODE)
  end

  def is_prescriber?
    activity_codes.include?(INDEPENDENT_PRESCRIBING_ACTIVITY_CODE)
  end

  def is_superuser?
    can_access_sensitive_flagged_records? ||
      can_perform_local_system_administration?
  end

  def can_access_sensitive_flagged_records?
    activity_codes.include?(ACCESS_SENSITIVE_FLAGGED_RECORDS_ACTIVITY_CODE)
  end

  def can_perform_local_system_administration?
    activity_codes.include?(LOCAL_SYSTEM_ADMINISTRATION_ACTIVITY_CODE)
  end

  def can_view_detailed_health_records?
    activity_codes.include?(VIEW_DETAILED_HEALTH_RECORDS_ACTIVITY_CODE)
  end

  def can_view_shared_non_patient_identifiable_information?
    activity_codes.include?(
      VIEW_SHARED_NON_PATIENT_IDENTIFIABLE_INFORMATION_ACTIVITY_CODE
    )
  end

  def is_support?
    is_support_without_pii_access? || is_support_with_pii_access?
  end

  def is_support_without_pii_access?
    is_support_without_activities? &&
      can_view_shared_non_patient_identifiable_information?
  end

  def is_support_with_pii_access?
    is_support_without_activities? && can_access_sensitive_flagged_records? &&
      can_view_detailed_health_records?
  end

  private

  def is_support_without_activities?
    workgroups&.include?(SUPPORT_WORKGROUP) && role_code == SUPPORT_ROLE &&
      organisation_code == SUPPORT_ORGANISATION
  end

  def request_session_key = "cis2_info"
end
