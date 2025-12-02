# frozen_string_literal: true

class ConsentNotificationPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      team_id = user.selected_team.id
      scope.joins(session: :team_location).where(team_location: { team_id: })
    end
  end
end
