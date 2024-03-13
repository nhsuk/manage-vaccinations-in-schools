class VaccinationsController < ApplicationController
  include TodaysBatchConcern
  include VaccinationMailerConcern

  before_action :set_session
  before_action :set_patient, except: %i[index record_template]
  before_action :set_patient_sessions, only: %i[index record_template]
  before_action :set_patient_session, only: %i[new confirm create record update]
  before_action :set_draft_vaccination_record,
                only: %i[edit_reason create update]
  before_action :set_draft_vaccination_record!, only: %i[confirm record]

  before_action :set_consent, only: %i[create confirm update]
  before_action :set_triage, only: %i[confirm]
  before_action :set_todays_batch_id, only: :create

  layout "two_thirds", except: :index

  def index
    tabs_to_states = {
      action_needed: %w[
        consent_given_triage_needed
        triaged_kept_in_triage
        triaged_ready_to_vaccinate
        added_to_session
        consent_refused
        consent_conflicts
        consent_given_triage_not_needed
      ],
      vaccinated: %w[vaccinated],
      vaccinate_later: %w[delay_vaccination],
      not_vaccinated: %w[
        triaged_do_not_vaccinate
        unable_to_vaccinate
        unable_to_vaccinate_not_assessed
        unable_to_vaccinate_not_gillick_competent
      ]
    }

    @partitioned_patient_sessions =
      @patient_sessions.group_by do |patient_session|
        tabs_to_states
          .find { |_, states| patient_session.state.in? states }
          &.first
      end

    # ensure all tabs are present
    tabs_to_states.each_key { |tab| @partitioned_patient_sessions[tab] ||= [] }

    respond_to do |format|
      format.html
      format.json { render json: @patient_outcomes.map(&:first).index_by(&:id) }
    end

    session[:current_section] = "vaccinations"
  end

  def new
    if @patient.vaccination_records_for_session(@session).any?
      raise UnprocessableEntity
    end
    @draft_vaccination_record =
      @patient.vaccination_records_for_session(@session).new
  end

  def edit_reason
  end

  def confirm
  end

  def record
    unless @draft_vaccination_record.update(
             confirm_params.merge(recorded_at: Time.zone.now)
           )
      render :confirm
      return
    end

    send_vaccination_mail(@draft_vaccination_record)
    @patient_session.do_vaccination!

    success_flash_after_patient_update(
      patient: @patient,
      view_record_link: session_patient_vaccinations_path(@session, @patient)
    )
    redirect_to vaccinations_session_path(@session)
  end

  def record_template
    flash[:success] = {
      heading: "Offline changes saved",
      body: "You will need to go online to sync your changes."
    }
    render :index
  end

  def create
    if @draft_vaccination_record.update create_params.merge(user: current_user)
      if @draft_vaccination_record.administered?
        if @draft_vaccination_record.delivery_site_other
          redirect_to edit_session_patient_vaccinations_delivery_site_path(
                        @session,
                        @patient
                      )
        elsif @draft_vaccination_record.batch_id.present?
          redirect_to confirm_session_patient_vaccinations_path(
                        @session,
                        @patient
                      )
        else
          redirect_to edit_session_patient_vaccinations_batch_path(
                        @session,
                        @patient
                      )
        end
      else
        redirect_to edit_reason_session_patient_vaccinations_path(
                      @session,
                      @patient
                    )
      end
    else
      render "patient_sessions/show"
    end
  end

  def update
    @draft_vaccination_record.assign_attributes(vaccination_record_params)
    if @draft_vaccination_record.save(context: :edit_reason)
      redirect_to confirm_session_patient_vaccinations_path(@session, @patient)
    else
      render :edit_reason
    end
  end

  private

  def vaccination_record_params
    params.fetch(:vaccination_record, {}).permit(
      :administered,
      :delivery_site,
      :delivery_method,
      :reason,
      :batch_id
    )
  end

  def create_params
    if vaccination_record_params[:administered] == "true"
      create_params =
        if delivery_site_param_other?
          vaccination_record_params_with_delivery_other
        else
          vaccination_record_params
        end
      create_params.merge(batch_id: @todays_batch_id)
    else
      vaccination_record_params
    end
  end

  def vaccination_record_params_with_delivery_other
    vaccination_record_params.except(:delivery_site, :delivery_method).merge(
      delivery_site_other: "true"
    )
  end

  def vaccination_record_administered_params
    params.fetch(:vaccination_record, {}).permit(:administered, :delivery_site)
  end

  def vaccination_record_reason_params
    params.fetch(:vaccination_record, {}).permit(:reason)
  end

  def consent_params
    params.fetch(:consent, {}).permit(:route)
  end

  def delivery_site_param_other?
    vaccination_record_params[:delivery_site] == "other"
  end

  def set_session
    @session =
      policy_scope(Session).find(
        params.fetch(:session_id) { params.fetch(:id) }
      )
  end

  def set_patient
    @patient =
      policy_scope(Patient).find(
        params.fetch(:patient_id) { params.fetch(:id) }
      )
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

  def set_draft_vaccination_record!
    set_draft_vaccination_record
    raise UnprocessableEntity unless @draft_vaccination_record.persisted?
  end

  def set_consent
    # HACK: Vaccinations needs to be updated to work with multiple consents.
    @consent = @patient_session.consents.first
  end

  def set_triage
    @triage = Triage.find_or_initialize_by(patient_session: @patient_session)
  end

  def set_patient_session
    @patient_session = @patient.patient_sessions.find_by(session: @session)
  end

  def set_todays_batch_id
    @todays_batch_id = todays_batch_id
  end

  def confirm_params
    params.fetch(:vaccination_record, {}).permit(:notes)
  end
end
