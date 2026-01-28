# frozen_string_literal: true

class PatientPolicy < ApplicationPolicy
  def index? = true

  def show? = true

  def update? = true

  def log? = team.has_poc_only_access?

  def pds_search_history? = show?

  def invite_to_clinic? = update?

  def edit_nhs_number? = edit?

  def edit_ethnic_group? = edit?

  def edit_ethnic_background? = edit?

  def edit_school? = edit?

  def update_nhs_number? = update?

  def update_ethnic_group? = update?

  def update_ethnic_background? = update?

  def update_nhs_number_merge? = update?

  def update_school? = update?

  class Scope < ApplicationPolicy::Scope
    def resolve
      if team
        scope.joins(:patient_teams).where(patient_teams: { team_id: team.id })
      else
        scope.none
      end
    end
  end
end
