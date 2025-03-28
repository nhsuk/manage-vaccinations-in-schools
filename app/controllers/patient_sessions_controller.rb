# frozen_string_literal: true

class PatientSessionsController < ApplicationController
  before_action :set_patient_session
  before_action :set_programme, except: :log
  before_action :set_session
  before_action :set_patient
  before_action :set_breadcrumb_item

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
      performed_by_user_id: current_user.id,
      programme: @programme,
      session: @session,
      location_name: @session.clinic? ? "Unknown" : nil,
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
            triage_statuses: :programme,
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

  def set_breadcrumb_item
    return_to = params[:return_to]
    return nil if return_to.blank?

    known_return_to = %w[consent triage register record outcome]
    return unless return_to.in?(known_return_to)

    @breadcrumb_item = {
      text: t(return_to, scope: %i[sessions tabs]),
      href: send(:"session_#{return_to}_path")
    }
  end

  def record_access_log_entry
    @patient.access_log_entries.create!(
      user: current_user,
      controller: "patient_sessions",
      action: action_name
    )
  end
end
