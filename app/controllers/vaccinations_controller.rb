# frozen_string_literal: true

require "pagy/extras/array"

class VaccinationsController < ApplicationController
  include Pagy::Backend

  include TodaysBatchConcern
  include VaccinationMailerConcern
  include PatientTabsConcern
  include PatientSortingConcern

  before_action :set_session
  before_action :set_patient, only: :create
  before_action :set_patient_session, only: :create
  before_action :set_programme, only: %i[index create]
  before_action :set_section_and_tab, only: :create

  before_action :set_todays_batch, only: %i[index create]

  after_action :verify_authorized

  def index
    authorize VaccinationRecord

    all_patient_sessions =
      @session
        .patient_sessions
        .preload_for_status
        .eager_load(:patient)
        .merge(Patient.in_programme(@programme))
        .order_by_name

    grouped_patient_sessions =
      group_patient_sessions_by_state(
        all_patient_sessions,
        @programme,
        section: :vaccinations
      )

    @current_tab = TAB_PATHS[:vaccinations][params[:tab]]
    @tab_counts = count_patient_sessions(grouped_patient_sessions)
    patient_sessions = grouped_patient_sessions.fetch(@current_tab, [])

    sort_and_filter_patients!(patient_sessions, programme: @programme)
    @pagy, @patient_sessions = pagy_array(patient_sessions)

    session[:current_section] = "vaccinations"

    respond_to do |format|
      format.html { render layout: "full" }
      format.json { render json: @patient_outcomes.map(&:first).index_by(&:id) }
    end
  end

  def create
    authorize VaccinationRecord

    draft_vaccination_record =
      DraftVaccinationRecord.new(request_session: session, current_user:)

    @vaccinate_form =
      VaccinateForm.new(
        patient_session: @patient_session,
        current_user:,
        todays_batch: @todays_batch,
        **vaccinate_form_params
      )

    if @vaccinate_form.save(draft_vaccination_record:)
      steps = draft_vaccination_record.wizard_steps

      steps.delete(:notes) # this is on the confirmation page

      steps.delete(:date_and_time)
      steps.delete(:outcome) if draft_vaccination_record.administered?
      if draft_vaccination_record.delivery_method.present? &&
           draft_vaccination_record.delivery_site.present?
        steps.delete(:delivery)
      end
      steps.delete(:vaccine) if draft_vaccination_record.vaccine.present?
      steps.delete(:batch) if draft_vaccination_record.batch.present?

      redirect_to draft_vaccination_record_path(
                    I18n.t(steps.first, scope: :wicked)
                  )
    else
      render "patient_sessions/show", status: :unprocessable_entity
    end
  end

  private

  def vaccinate_form_params
    params.expect(
      vaccinate_form: %i[
        administered
        delivery_method
        delivery_site
        dose_sequence
        feeling_well
        knows_vaccination
        no_allergies
        not_already_had
        pre_screening_notes
        programme_id
        vaccine_id
      ]
    )
  end

  def set_session
    @session =
      policy_scope(Session).includes(:location, :programmes).find_by!(
        slug: params[:session_slug] || params[:slug]
      )
  end

  def set_patient
    @patient =
      policy_scope(Patient).find(
        params.fetch(:patient_id) { params.fetch(:id) }
      )
  end

  def set_patient_session
    @patient_session =
      @patient
        .patient_sessions
        .includes(
          :gillick_assessments,
          :organisation,
          patient: {
            parent_relationships: :parent
          }
        )
        .preload_for_status
        .find_by!(session: @session)
  end

  def set_programme
    if @patient_session.present?
      @programme =
        @patient_session.programmes.find { it.type == params[:programme_type] }

      raise ActiveRecord::RecordNotFound if @programme.nil?
    else
      @programme =
        @session.programmes.find_by(type: params[:programme_type]) ||
          @session.programmes.first
    end
  end

  def set_section_and_tab
    @section = params[:section]
    @tab = params[:tab]
  end

  def set_todays_batch
    @todays_batch =
      policy_scope(Batch)
        .where(vaccine: @session.vaccines)
        .not_archived
        .not_expired
        .find_by(id: todays_batch_id(programme: @programme))
  end
end
