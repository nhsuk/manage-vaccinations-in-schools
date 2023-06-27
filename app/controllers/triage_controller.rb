class TriageController < ApplicationController
  before_action :set_session, only: %i[show create update]
  before_action :set_patient, only: %i[show create update]
  before_action :set_triage, only: %i[show]
  before_action :set_consent_response, only: %i[show]

  def index
    @session = Session.find_by(id: params[:id])
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

  def create
    @triage = Triage.new(campaign: @session.campaign, patient: @patient)
    if @triage.update(triage_params)
      redirect_to triage_session_path(@session)
    else
      render :show, status: :unprocessable_entity
    end
  end

  def update
    @triage = @patient.triage_for_campaign(@session.campaign)
    if @triage.update(triage_params)
      redirect_to triage_session_path(@session)
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

  def set_session
    @session = Session.find_by(id: params[:session_id])
  end

  def set_patient
    @patient = @session.patients.find_by(id: params[:patient_id])
  end

  def set_triage
    @triage =
      @patient.triage_for_campaign(@session.campaign) ||
        Triage.new(campaign: @session.campaign, patient: @patient)
  end

  def set_consent_response
    @consent_response =
      @patient.consent_response_for_campaign(@session.campaign)
  end

  def triage_params
    params.require(:triage).permit(:status, :notes)
  end
end
