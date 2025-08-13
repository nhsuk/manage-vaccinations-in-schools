# frozen_string_literal: true

class PatientsController < ApplicationController
  include PatientSearchFormConcern

  before_action :set_patient_search_form, only: :index
  before_action :set_patient, except: :index
  before_action :set_patient_sessions, only: :show
  before_action :set_in_generic_clinic, only: :show
  before_action :record_access_log_entry, only: %i[show log]

  layout "full"

  def index
    patients = @form.apply(policy_scope(Patient).includes(:school))

    @pagy, @patients = pagy(patients)
  end

  def show
  end

  def log
  end

  def edit
  end

  def invite_to_clinic
    session =
      current_team.generic_clinic_session(academic_year: AcademicYear.pending)

    PatientSession.find_or_create_by!(patient: @patient, session:)

    redirect_to patient_path(@patient),
                flash: {
                  success: "#{@patient.full_name} invited to the clinic"
                }
  end

  private

  def set_patient
    @patient =
      policy_scope(Patient).includes(
        :gp_practice,
        :school,
        consents: %i[parent patient],
        parent_relationships: :parent,
        patient_sessions: %i[location session_attendances],
        vaccination_records: :programme
      ).find(params[:id])
  end

  def set_patient_sessions
    @patient_sessions =
      policy_scope(PatientSession)
        .includes_programmes
        .includes(session: :location)
        .where(patient: @patient)
  end

  def set_in_generic_clinic
    generic_clinic_session =
      current_team.generic_clinic_session(academic_year: AcademicYear.pending)
    @in_generic_clinic =
      @patient.patient_sessions.exists?(session: generic_clinic_session)
  end

  def record_access_log_entry
    @patient.access_log_entries.create!(
      user: current_user,
      controller: "patients",
      action: action_name
    )
  end
end
