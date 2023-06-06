class SessionsController < ApplicationController
  before_action :set_session, only: %i[show]

  def index
    @sessions_by_type = Session.all.group_by(&:type)
  end

  def show
  end

  private

  def set_session
    @session = Session.find(params[:id])
  end
end
