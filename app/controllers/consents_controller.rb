# frozen_string_literal: true

require "pagy/extras/array"

class ConsentsController < ApplicationController
  include Pagy::Backend

  include PatientTabsConcern
  include PatientSortingConcern

  before_action :set_session
  before_action :set_patient_session, except: :index
  before_action :set_programme, except: :index
  before_action :set_patient, except: :index
  before_action :set_consent, except: %i[index create send_request]
  before_action :ensure_can_withdraw, only: %i[edit_withdraw update_withdraw]
  before_action :ensure_can_invalidate,
                only: %i[edit_invalidate update_invalidate]

  def index
    @programme =
      @session.programmes.find_by(type: params[:programme_type]) ||
        @session.programmes.first

    all_patient_sessions =
      @session
        .patient_sessions
        .preload_for_status
        .preload(patient: { consents: %i[parent patient] })
        .eager_load(:patient)
        .merge(Patient.in_programme(@programme))
        .order_by_name

    tab_patient_sessions =
      group_patient_sessions_by_conditions(
        all_patient_sessions,
        programme: @programme,
        section: :consents
      )

    @current_tab = TAB_PATHS[:consents][params[:tab]]
    @tab_counts = count_patient_sessions(tab_patient_sessions)
    patient_sessions = tab_patient_sessions[@current_tab] || []

    sort_and_filter_patients!(patient_sessions, programme: @programme)
    @pagy, @patient_sessions = pagy_array(patient_sessions)

    session[:current_section] = "consents"

    render layout: "full"
  end

  def create
    authorize Consent

    @draft_consent =
      DraftConsent.new(request_session: session, current_user:).tap(&:reset!)

    @draft_consent.assign_attributes(create_params)

    if @draft_consent.save
      redirect_to draft_consent_path(Wicked::FIRST_STEP)
    else
      render "patient_sessions/show", status: :unprocessable_entity
    end
  end

  def send_request
    return unless @patient_session.no_consent?(programme: @programme)

    # For programmes that are administered together we should send the consent request together.
    programmes =
      ProgrammeGrouper
        .call(@session.programmes)
        .values
        .find { it.include?(@programme) }

    ConsentNotification.create_and_send!(
      patient: @patient,
      programmes:,
      session: @session,
      type: :request,
      current_user:
    )

    redirect_to session_patient_programme_path(
                  @session,
                  @patient,
                  @programme,
                  section: params[:section],
                  tab: params[:tab]
                ),
                flash: {
                  success: "Consent request sent."
                }
  end

  def show
  end

  def edit_withdraw
    render :withdraw
  end

  def update_withdraw
    @consent.assign_attributes(withdraw_params)

    if @consent.valid?
      ActiveRecord::Base.transaction do
        @consent.save!
        @patient
          .triages
          .where(programme_id: @consent.programme_id)
          .invalidate_all
      end

      redirect_to session_patient_programme_consent_path
    else
      render :withdraw, status: :unprocessable_entity
    end
  end

  def edit_invalidate
    render :invalidate
  end

  def update_invalidate
    @consent.assign_attributes(invalidate_params)

    if @consent.valid?
      ActiveRecord::Base.transaction do
        @consent.save!
        @patient
          .triages
          .where(programme_id: @consent.programme_id)
          .invalidate_all
      end

      redirect_to session_patient_programme_consent_path,
                  flash: {
                    success:
                      "Consent response from #{@consent.name} marked as invalid"
                  }
    else
      render :invalidate, status: :unprocessable_entity
    end
  end

  private

  def set_session
    @session =
      policy_scope(Session).includes(:location, :organisation).find_by!(
        slug: params[:session_slug]
      )
  end

  def set_patient_session
    @patient_session =
      policy_scope(PatientSession).includes(
        :gillick_assessments,
        session: :programmes
      ).find_by!(session: @session, patient_id: params[:patient_id])
  end

  def set_programme
    @programme =
      @patient_session.programmes.find { it.type == params[:programme_type] }

    raise ActiveRecord::RecordNotFound if @programme.nil?
  end

  def set_patient
    @patient = @patient_session.patient
  end

  def set_consent
    @consent =
      @patient
        .consents
        .includes(:consent_form, :parent, patient: :parent_relationships)
        .find(params[:id])
  end

  def ensure_can_withdraw
    redirect_to action: :show unless @consent.can_withdraw?
  end

  def ensure_can_invalidate
    redirect_to action: :show unless @consent.can_invalidate?
  end

  def create_params
    {
      patient_session: @patient_session,
      programme: @programme,
      recorded_by: current_user
    }
  end

  def withdraw_params
    params.expect(consent: %i[reason_for_refusal notes]).merge(
      response: "refused",
      withdrawn_at: Time.current
    )
  end

  def invalidate_params
    params.expect(consent: :notes).merge(invalidated_at: Time.current)
  end
end
