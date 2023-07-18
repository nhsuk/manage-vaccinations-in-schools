class ConsentResponsesController < ApplicationController
  before_action :set_session
  before_action :set_patient

  def confirm
  end

  private

  def set_session
    @session = Session.find_by(id: params[:session_id])
  end

  def set_patient
    @patient = @session.patients.find_by(id: params[:id])
  end
end
