class TriageController < ApplicationController
  before_action :set_session, only: %i[show create update]
  before_action :set_patient, only: %i[show create update]
  before_action :set_triage, only: %i[show]
  before_action :set_consent_response, only: %i[show]
  before_action :set_vaccination_record, only: %i[show]

  layout "two_thirds"

  def index
    @session = Session.find_by(id: params[:id])
    @patient_details =
      @session
        .patient_sessions
        .includes(:patient)
        .order("patients.first_name", "patients.last_name")
        .map do |ps|
          consent = ps.patient.consent_response_for_campaign(@session.campaign)
          triage = ps.patient.triage_for_campaign(@session.campaign)
          vaccination_record = ps.vaccination_records.last

          action_or_outcome =
            PatientActionOrOutcomeService.call(
              consent:,
              triage:,
              vaccination_record:
            )
          [ps.patient, action_or_outcome]
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

  def set_vaccination_record
    @vaccination_record =
      @patient
        .vaccination_records_for_session(@session)
        .where.not(recorded_at: nil)
        .first
  end

  def triage_params
    params.require(:triage).permit(:status, :notes)
  end
end
