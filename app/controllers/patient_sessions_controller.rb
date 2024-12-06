# frozen_string_literal: true

class PatientSessionsController < ApplicationController
  before_action :set_patient_session
  before_action :set_session
  before_action :set_patient
  before_action :set_section_and_tab
  before_action :record_access_log_entry

  layout "three_quarters"

  def show
  end

  def log
  end

  private

  def set_patient_session
    @patient_session =
      policy_scope(PatientSession)
        .includes(:patient, :vaccination_records)
        .eager_load(:session)
        .preload(:consents, :gillick_assessments, :pre_screenings, :triages)
        .find_by!(
          session: {
            slug: params.fetch(:session_slug)
          },
          patient_id: params.fetch(:id, params[:patient_id])
        )
  end

  def set_session
    @session = @patient_session.session
  end

  def set_patient
    @patient = @patient_session.patient
  end

  def set_section_and_tab
    @section = params[:section]
    @tab = params[:tab]
  end

  def record_access_log_entry
    @patient.access_log_entries.create!(
      user: current_user,
      controller: "patient_sessions",
      action: action_name
    )
  end
end
