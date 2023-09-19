class SessionsController < ApplicationController
  before_action :set_session, only: %i[show]

  def index
    @sessions_by_type = policy_scope(Session).group_by(&:type)
  end

  def show
  end

  private

  def set_session
    @session = policy_scope(Session).find(params[:id])
  end
end
