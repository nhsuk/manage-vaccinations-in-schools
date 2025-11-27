# frozen_string_literal: true

class VaccinationRecordPolicy < ApplicationPolicy
  def create?
    return true if user.is_nurse? || user.is_prescriber?
    return false unless user.is_healthcare_assistant?
    return true if patient.nil?

    vaccine_criteria = patient.vaccine_criteria(programme:, academic_year:)

    can_create_with_psd?(vaccine_criteria) ||
      can_create_with_national_protocol?(vaccine_criteria) ||
      can_create_with_pgd_supply?(vaccine_criteria)
  end

  def new? = create?

  def record_already_vaccinated?
    return unless user.is_nurse? || user.is_prescriber?
    return if session.today?

    vaccination_status = patient.vaccination_status(programme:, academic_year:)

    vaccination_status.not_eligible? || vaccination_status.eligible?
  end

  def edit?
    (
      record.performed_by_user_id == user.id || user.is_nurse? ||
        user.is_prescriber?
    ) && record.recorded_in_service? &&
      record.performed_ods_code == user.selected_organisation.ods_code
  end

  def update? = edit?

  def destroy?
    user.can_perform_local_system_administration? &&
      !record.sourced_from_nhs_immunisations_api?
  end

  private

  delegate :patient, :session, :programme, :programme_type, to: :record
  delegate :academic_year, :team, to: :session

  def can_create_with_psd?(vaccine_criteria)
    session.psd_enabled? &&
      vaccine_criteria.vaccine_methods.any? do |vaccine_method|
        patient.has_patient_specific_direction?(
          academic_year:,
          programme_type:,
          team:,
          vaccine_method:
        )
      end
  end

  def can_create_with_national_protocol?(vaccine_criteria)
    session.national_protocol_enabled? &&
      vaccine_criteria.vaccine_methods.include?("injection")
  end

  def can_create_with_pgd_supply?(vaccine_criteria)
    session.pgd_supply_enabled? &&
      vaccine_criteria.vaccine_methods.include?("nasal")
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      team = user.selected_team
      return scope.none if team.nil?

      scope
        .kept
        .joins(
          "INNER JOIN patient_teams on patient_teams.patient_id = vaccination_records.patient_id"
        )
        .where(patient_teams: { team_id: team.id })
        .merge(
          PatientTeam.where_any_sources(
            %w[vaccination_record_session vaccination_record_organisation]
          )
        )
    end
  end
end
