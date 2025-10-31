# frozen_string_literal: true

class PatientsController < ApplicationController
  include PatientSearchFormConcern

  before_action :set_patient_search_form, only: :index
  before_action :set_patient, except: :index
  before_action :set_in_generic_clinic, only: :show
  before_action :record_access_log_entry, only: %i[show log]
  before_action :set_search_params_present, only: :index
  skip_after_action :verify_policy_scoped, only: :index

  layout "full"

  def index
    if @search_params_present
      scope =
        policy_scope(Patient).includes(
          :consent_statuses,
          :location_programme_year_groups,
          :school,
          :triage_statuses,
          :vaccination_statuses
        )

      patients = @form.apply(scope)
    else
      patients = Patient.none
    end

    @pagy, @patients = pagy(patients)
  end

  def show
  end

  def log
  end

  def edit
  end

  def pds_search_history
    latest_results = @patient.pds_search_results.includes(:import).latest_set

    @timeline_items =
      if latest_results.present?
        latest_results
          .map(&:timeline_item)
          .sort_by { |item| item["created_at"] }
      else
        []
      end

    time = latest_results&.last&.import&.processed_at

    if @patient.nhs_number.present?
      @timeline_items << {
        active: true,
        heading_text: "NHS number is #{@patient.nhs_number}",
        description: time&.to_date&.to_fs(:long)
      }
    end
  end

  def invite_to_clinic
    PatientLocation.find_or_create_by!(
      patient: @patient,
      location: current_team.generic_clinic,
      academic_year: AcademicYear.pending
    )

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
        vaccination_records: :programme
      ).find(params[:id])
  end

  def set_in_generic_clinic
    @in_generic_clinic =
      @patient.patient_locations.exists?(
        location: current_team.generic_clinic,
        academic_year: AcademicYear.pending
      )
  end

  def record_access_log_entry
    @patient.access_log_entries.create!(
      user: current_user,
      controller: "patients",
      action: action_name
    )
  end

  def set_search_params_present
    @search_params_present = @form.any_filters_applied?
  end
end
