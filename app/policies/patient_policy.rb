# frozen_string_literal: true

class PatientPolicy < ApplicationPolicy
  def log? = show?

  def pds_search_history? = show?

  def invite_to_clinic? = update?

  def edit_nhs_number? = edit?

  def edit_school? = edit?

  def update_nhs_number? = update?

  def update_nhs_number_merge? = update?

  def update_school? = update?

  class Scope < ApplicationPolicy::Scope
    def resolve
      team = user.selected_team

      return scope.none if team.nil?

      scope.joins(:patient_teams).where(patient_teams: { team_id: team.id })
    end
  end
end
