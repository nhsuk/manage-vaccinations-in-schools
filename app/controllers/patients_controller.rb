# frozen_string_literal: true

class PatientsController < ApplicationController
  include Pagy::Backend
  include SearchFormConcern

  before_action :set_search_form, only: :index
  before_action :set_patient, except: :index
  before_action :record_access_log_entry, only: %i[show log]

  def index
    patients =
      @form.apply(
        policy_scope(Patient).includes(:school).not_deceased.order_by_name
      )

    @pagy, @patients = pagy(patients)

    render layout: "full"
  end

  def show
    @patient_sessions =
      policy_scope(PatientSession).where(patient: @patient).includes(
        session: %i[location programmes]
      )
  end

  def log
  end

  def edit
  end

  def update
    old_organisation = @patient.organisation

    organisation_id = params.dig(:patient, :organisation_id).presence

    ActiveRecord::Base.transaction do
      @patient.update!(organisation_id:)

      if organisation_id.nil?
        @patient
          .patient_sessions
          .preload_for_status
          .includes(:gillick_assessments, :session_attendances)
          .where(session: old_organisation.sessions)
          .find_each(&:destroy_if_safe!)
      end
    end

    path =
      (
        if policy_scope(Patient).include?(@patient)
          patient_path(@patient)
        else
          patients_path
        end
      )

    redirect_to path,
                flash: {
                  success: "#{@patient.full_name} removed from cohort"
                }
  end

  private

  def set_patient
    @patient =
      policy_scope(Patient).includes(
        :gillick_assessments,
        :gp_practice,
        :organisation,
        :school,
        :triages,
        consents: %i[parent patient],
        parent_relationships: :parent,
        patient_sessions: %i[location session_attendances],
        vaccination_records: [{ vaccine: :programme }]
      ).find(params[:id])
  end

  def record_access_log_entry
    @patient.access_log_entries.create!(
      user: current_user,
      controller: "patients",
      action: action_name
    )
  end
end
