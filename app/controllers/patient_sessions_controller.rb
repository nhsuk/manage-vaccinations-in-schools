# frozen_string_literal: true

class PatientSessionsController < ApplicationController
  before_action :set_patient_session
  before_action :set_programme, except: :log
  before_action :set_session
  before_action :set_patient
  before_action :set_back_link_path

  before_action :record_access_log_entry, except: :record_already_vaccinated

  layout "three_quarters"

  def show
  end

  def log
  end

  def record_already_vaccinated
    unless @patient_session.can_record_as_already_vaccinated?(
             programme: @programme
           )
      redirect_to session_patient_path and return
    end

    draft_vaccination_record =
      DraftVaccinationRecord.new(request_session: session, current_user:)

    draft_vaccination_record.reset!
    draft_vaccination_record.update!(
      outcome: :already_had,
      patient: @patient,
      performed_at: Time.current,
      performed_by_user_id: nil,
      programme: @programme,
      # TODO: Ideally we wouldn't set these, but other parts of the service break if we don't.
      # These are set when recording an "already had" vaccination normally, and we probably
      # want to change that too.
      session: @session,
      performed_ods_code: current_user.selected_organisation.ods_code
    )

    redirect_to draft_vaccination_record_path("confirm")
  end

  private

  def set_patient_session
    @patient_session =
      policy_scope(PatientSession)
        .eager_load(:location, :session, patient: %i[gp_practice school])
        .preload(
          :gillick_assessments,
          :session_attendances,
          patient: {
            consents: %i[parent],
            parent_relationships: :parent,
            triages: :performed_by,
            vaccination_records: {
              vaccine: :programme
            }
          },
          session: :programmes
        )
        .find_by!(
          session: {
            slug: params[:session_slug]
          },
          patient_id: params.fetch(:id, params[:patient_id])
        )
  end

  def set_programme
    @programme =
      @patient_session.programmes.find { it.type == params[:programme_type] }

    raise ActiveRecord::RecordNotFound if @programme.nil?
  end

  def set_session
    @session = @patient_session.session
  end

  def set_patient
    @patient = @patient_session.patient
  end

  def set_back_link_path
    context = params[:return_to]
    context_path = try(:"session_#{context}_path")
    @back_link_path = context_path || session_outcome_path
  end

  def record_access_log_entry
    @patient.access_log_entries.create!(
      user: current_user,
      controller: "patient_sessions",
      action: action_name
    )
  end
end
