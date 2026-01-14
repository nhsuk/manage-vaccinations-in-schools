# frozen_string_literal: true

class ImportantNoticePolicy < ApplicationPolicy
  def index?
    user.can_access_sensitive_flagged_records?
  end

  alias_method :dismiss?, :index?
  alias_method :destroy?, :index?

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.joins(:patient).active(team:).where(team_id: team.id)
    end
  end
end
