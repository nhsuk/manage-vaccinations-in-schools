class VaccinationsController < ApplicationController
  before_action :set_session
  before_action :set_patient, except: %i[index record_template]
  before_action :set_patient_sessions, only: %i[index record_template]
  before_action :set_patient_session, only: %i[consent create record show]
  before_action :set_draft_vaccination_record,
                only: %i[show confirm edit_reason record create update]

  before_action :set_vaccination_record, only: %i[show confirm record]
  before_action :set_consent_response, only: %i[create show confirm]
  before_action :set_triage, only: %i[show confirm]
  before_action :set_draft_consent_response, only: %i[show consent]
  before_action :set_todays_batch_id, only: :create

  layout "two_thirds", except: :index

  def index
    respond_to do |format|
      format.html
      format.json { render json: @patient_outcomes.map(&:first).index_by(&:id) }
    end
  end

  def show
    respond_to do |format|
      format.html
      format.json { render json: @patient }
    end
  end

  def edit_reason
  end

  def confirm
  end

  def record
    @draft_vaccination_record.update!(recorded_at: Time.zone.now)
    @patient_session.do_vaccination!
    if Settings.features.fhir_server_integration
      imm =
        ImmunizationFHIRBuilder.new(
          patient_identifier: @patient.nhs_number,
          occurrence_date_time: Time.zone.now
        )
      imm.immunization.create # rubocop:disable Rails/SaveBang
    end
    redirect_to vaccinations_session_path(@session),
                flash: {
                  success: {
                    title: "Record saved for #{@patient.full_name}",
                    body: ActionController::Base.helpers.link_to(
                      "View child record",
                      session_patient_vaccinations_path(@session, @patient)
                    ),
                  },
                }
  end

  def history
    if Settings.features.fhir_server_integration
      fhir_bundle =
        FHIR::Immunization.search(
          patient:
            "https://sandbox.api.service.nhs.uk/personal-demographics/FHIR/R4/Patient/#{@patient.nhs_number}"
        )
      @history =
        fhir_bundle
          .entry
          .map(&:resource)
          .map { |entry| FHIRVaccinationEvent.new(entry) }
    else
      raise "`features.fhir_server_integration` is not enabled in Settings"
    end
  end

  def show_template
    @patient = Patient.new
    render "show"
  end

  def record_template
    flash[:success] = {
      title: "Offline changes saved",
      body: "You will need to go online to sync your changes."
    }
    render :index
  end

  def create
    @draft_vaccination_record.assign_attributes(vaccination_record_params)

    if @draft_vaccination_record.administered?
      @draft_vaccination_record.batch_id = @todays_batch_id
    end

    if @draft_vaccination_record.save
      if @draft_vaccination_record.administered?
        if @draft_vaccination_record.batch_id.present?
          redirect_to confirm_session_patient_vaccinations_path(@session, @patient)
        else
          redirect_to edit_session_patient_vaccinations_batch_path(@session, @patient)
        end
      else
        redirect_to edit_reason_session_patient_vaccinations_path(@session, @patient)
      end
    else
      render :show
    end
  end

  def update
    if @draft_vaccination_record.update(vaccination_record_params)
      redirect_to confirm_session_patient_vaccinations_path(@session, @patient)
    elsif @draft_vaccination_record.administered?
      redirect_to edit_batch_session_patient_vaccinations_path(@session, @patient)
    else
      redirect_to edit_reason_session_patient_vaccinations_path(@session, @patient)
    end
  end

  def consent
    case consent_response_params[:route]
    when "not_vaccinating"
      @patient_session.do_vaccination!
      redirect_to vaccinations_session_path(@session),
        flash: {
          success: {
            title: "Record saved for #{@patient.full_name}",
            body: ActionController::Base.helpers.link_to(
              "View child record",
              session_patient_vaccinations_path(@session, @patient)
            ),
          },
        }
    when "phone"
      redirect_to new_session_patient_consent_responses_path(@session, @patient)
    when "self_consent"
      redirect_to assessing_gillick_session_patient_consent_responses_path(@session, @patient)
    end
  end

  private

  def vaccination_record_params
    params.require(:vaccination_record)
      .permit(:administered, :site, :reason, :batch_id)
  end

  def vaccination_record_administered_params
    params.fetch(:vaccination_record, {})
      .permit(:administered, :site)
  end

  def vaccination_record_reason_params
    params.fetch(:vaccination_record, {})
      .permit(:reason)
  end

  def consent_response_params
    params.fetch(:consent_response, {}).permit(:route)
  end

  def set_session
    @session = Session.find(params.fetch(:session_id) { params.fetch(:id) })
  end

  def set_patient
    @patient = Patient.find(params.fetch(:patient_id) { params.fetch(:id) })
  end

  def set_patient_sessions
    @patient_sessions =
      @session
        .patient_sessions
        .includes(:patient)
        .order("patients.first_name", "patients.last_name")
  end

  def set_draft_vaccination_record
    @draft_vaccination_record =
      @patient.vaccination_records_for_session(@session).find_or_initialize_by(
        recorded_at: nil
      )
  end

  def set_vaccination_record
    @vaccination_record =
      @patient
        .vaccination_records_for_session(@session)
        .where.not(recorded_at: nil)
        .first
  end

  def set_consent_response
    @consent_response =
      @patient.consent_response_for_campaign(@session.campaign)
  end

  def set_triage
    @triage =
      @patient.triage_for_campaign(@session.campaign) ||
        Triage.new(campaign: @session.campaign, patient: @patient)
  end

  def set_patient_session
    @patient_session = @patient.patient_sessions.find_by(session: @session)
  end

  def set_draft_consent_response
    @draft_consent_response = @patient
      .consent_responses
      .find_or_initialize_by(recorded_at: nil)
  end

  def set_todays_batch_id
    if session.key?(:todays_batch_id) && session.key?(:todays_batch_date) &&
       session[:todays_batch_date] == Time.zone.now.to_date.to_s
      @todays_batch_id = session[:todays_batch_id]
    end
  end
end
