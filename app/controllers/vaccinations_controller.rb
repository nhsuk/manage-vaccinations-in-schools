class VaccinationsController < ApplicationController
  before_action :set_session
  before_action :set_patient, only: %i[show confirm reason record history]
  before_action :set_patient_sessions, only: %i[index record_template]
  before_action :set_draft_vaccination_record,
                only: %i[show confirm reason record]
  before_action :set_vaccination_record, only: %i[show confirm record]
  before_action :set_consent_response, only: %i[show confirm]
  before_action :set_triage, only: %i[show confirm]

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

  def reason
  end

  def confirm
    if @draft_vaccination_record.update(vaccination_record_params)
      not_administered = !@draft_vaccination_record.administered?
      reason_not_specified = vaccination_record_params[:reason].blank?
      ask_for_reason = not_administered && reason_not_specified
      if ask_for_reason
        redirect_to reason_session_vaccination_path(@session, @patient)
      end
      # Render confirm
    else
      render :show
    end
  end

  def record
    @draft_vaccination_record.update!(recorded_at: Time.zone.now)
    @patient_session = @patient.patient_sessions.find_by(session: @session)
    @patient_session.do_vaccination!
    if Settings.features.fhir_server_integration
      imm =
        ImmunizationFHIRBuilder.new(
          patient_identifier: @patient.nhs_number,
          occurrence_date_time: Time.zone.now
        )
      imm.immunization.create # rubocop:disable Rails/SaveBang
    end
    redirect_to session_vaccinations_path(@session),
                flash: {
                  success: {
                    title: "Record saved for #{@patient.full_name}",
                    body:
                      ActionController::Base.helpers.link_to(
                        "View child record",
                        session_vaccination_path(@session, @patient)
                      )
                  }
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

  private

  def vaccination_record_params
    p = params.require(:vaccination_record)
    p[:site] = p[:site].to_i if p[:site].present?
    p.permit(:administered, :site, :reason)
  end

  def set_session
    @session = Session.find(params[:session_id])
  end

  def set_patient
    @patient = Patient.find(params[:id])
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
end
