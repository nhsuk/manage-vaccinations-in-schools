# frozen_string_literal: true

class VaccinationRecordPolicy < ApplicationPolicy
  def create?
    return true if user.is_nurse? || user.is_prescriber?
    return false unless user.is_healthcare_assistant?

    approved_vaccine_methods =
      patient.approved_vaccine_methods(programme:, academic_year:)

    can_create_with_psd?(approved_vaccine_methods) ||
      can_create_with_national_protocol?(approved_vaccine_methods) ||
      can_create_with_pgd_supply?(approved_vaccine_methods)
  end

  def new? = create?

  def record_already_vaccinated?
    (user.is_nurse? || user.is_prescriber?) && !session.today? &&
      patient.vaccination_status(programme:, academic_year:).none_yet?
  end

  def edit?
    (
      record.performed_by_user_id == user.id || user.is_nurse? ||
        user.is_prescriber?
    ) && record.recorded_in_service? &&
      record.performed_ods_code == user.selected_organisation.ods_code
  end

  def update? = edit?

  def destroy? = user.is_superuser?

  private

  delegate :patient, :session, :programme, to: :record
  delegate :academic_year, :team, to: :session

  def can_create_with_psd?(approved_vaccine_methods)
    session.psd_enabled? &&
      approved_vaccine_methods.any? do |vaccine_method|
        patient.has_patient_specific_direction?(
          academic_year:,
          programme:,
          team:,
          vaccine_method:
        )
      end
  end

  def can_create_with_national_protocol?(approved_vaccine_methods)
    session.national_protocol_enabled? &&
      approved_vaccine_methods.include?("injection")
  end

  def can_create_with_pgd_supply?(approved_vaccine_methods)
    session.pgd_supply_enabled? && approved_vaccine_methods.include?("nasal")
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      organisation = user.selected_organisation
      team = user.selected_team
      return scope.none if team.nil?

      scope
        .kept
        .where(patient: team.patients)
        .or(scope.kept.where(session: team.sessions))
        .or(
          scope.kept.where(
            performed_ods_code: organisation.ods_code,
            session_id: nil
          )
        )
    end
  end
end
