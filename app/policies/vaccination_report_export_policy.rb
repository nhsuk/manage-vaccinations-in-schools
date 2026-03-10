# frozen_string_literal: true

class VaccinationReportExportPolicy < ApplicationPolicy
  def create?
    team_member? && team_has_programme? && export_team.has_point_of_care_access?
  end

  def form_options?
    team_member? && export_team.has_point_of_care_access?
  end

  def index?
    team_member? && export_team.has_point_of_care_access?
  end

  def show?
    team_member?
  end

  def download?
    show? && record.ready? && !record.expired? && record.file.attached?
  end

  private

  def team_member?
    user.team_ids.include?(record.team_id)
  end

  def team_has_programme?
    record.programme_type.in?(export_team.programme_types.map(&:to_s))
  end

  def export_team
    record.team
  end
end
