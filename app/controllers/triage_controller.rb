class TriageController < ApplicationController
  before_action :set_session, only: [:index]

  def index
    @patient_triages =
      @session
        .patients
        .includes(:triage)
        .map do |patient|
          [patient, patient.triage_for_campaign(@session.campaign)]
        end
  end

  private

  def set_session
    @session = Session.find_by(id: params[:session_id])
  end
end
