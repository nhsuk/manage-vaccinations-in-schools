class SessionsController < ApplicationController
  before_action :set_session, only: %i[show]

  def index
  end

  def show
  end

  private

  def set_session
    @session = Session.find(params[:id])
  end
end
