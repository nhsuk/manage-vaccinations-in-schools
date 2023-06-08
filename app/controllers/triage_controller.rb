class TriageController < ApplicationController
  before_action :set_session, only: [:index]

  def index
    @patients = @session.patients
  end

  private

  def set_session
    @session = Session.find_by(id: params[:session_id])
  end
end
