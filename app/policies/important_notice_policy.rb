# frozen_string_literal: true

class ImportantNoticePolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      scope
        .joins(:patient)
        .active(team: user.selected_team)
        .where(team_id: user.selected_team.id)
    end
  end

  def index?
    user.can_access_sensitive_flagged_records?
  end

  def show?
    record.team_id == user.selected_team.id &&
      user.can_perform_local_system_administration?
  end
end
