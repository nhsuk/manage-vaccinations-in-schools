class TriageController < ApplicationController
  before_action :set_session, only: %i[index show]
  before_action :set_patient, only: [:show]
  before_action :set_triage, only: [:show]
  before_action :set_consent_response, only: [:show]

  def index
    @patient_triages =
      @session
        .patients
        .includes(:triage)
        .order("first_name", "last_name")
        .map do |patient|
          [
            patient,
            patient.triage_for_campaign(@session.campaign),
            patient.consent_response_for_campaign(@session.campaign)
          ]
        end
  end

  def show
  end

  private

  def set_session
    @session = Session.find_by(id: params[:session_id])
  end

  def set_patient
    @patient = Patient.find_by(id: params[:id])
  end

  def set_triage
    @triage = @patient.triage_for_campaign(@session.campaign)
  end

  def set_consent_response
    @consent_response =
      @patient.consent_response_for_campaign(@session.campaign)
  end
end
