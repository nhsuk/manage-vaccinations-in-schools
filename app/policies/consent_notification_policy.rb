# frozen_string_literal: true

class ConsentNotificationPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.joins(session: :team_location).where(
        team_location: {
          team_id: team.id
        }
      )
    end
  end
end
