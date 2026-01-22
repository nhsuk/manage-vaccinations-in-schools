# frozen_string_literal: true

class PatientsController < ApplicationController
  include PatientSearchFormConcern

  before_action :set_patient_search_form, only: :index
  before_action :set_search_params_present, only: :index
  before_action :set_programmes, only: :index
  before_action :set_programme_statuses, only: :index
  before_action :set_visibility_flags, only: :index
  before_action :set_patient, except: :index
  before_action :set_in_generic_clinic, only: :show
  before_action :record_access_log_entry, only: %i[show log]

  layout "full"

  def index
    authorize Patient

    patients =
      if @search_params_present
        scope = policy_scope(Patient).includes_statuses.includes(:school)
        @form.apply(scope)
      else
        skip_policy_scope
        Patient.none
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
    ActiveRecord::Base.transaction do
      PatientLocation.find_or_create_by!(
        patient: @patient,
        location: current_team.generic_clinic,
        academic_year: AcademicYear.pending
      )

      PatientTeamUpdater.call(
        patient_scope: Patient.where(id: @patient.id),
        team_scope: Team.where(id: current_team.id)
      )
    end

    redirect_to patient_path(@patient),
                flash: {
                  success: "#{@patient.full_name} invited to the clinic"
                }
  end

  private

  def set_search_params_present
    @search_params_present = @form.any_filters_applied?
  end

  def set_programmes
    @programmes =
      (current_team.has_upload_only_access? ? [] : current_team.programmes)
  end

  def set_programme_statuses
    @programme_statuses =
      if current_team.has_upload_only_access?
        []
      else
        Patient::ProgrammeStatus.statuses.keys -
          %w[
            not_eligible
            needs_consent_request_not_scheduled
            needs_consent_request_scheduled
            needs_consent_request_failed
            needs_consent_follow_up_requested
          ]
      end
  end

  def set_visibility_flags
    upload_only_access = current_team.has_upload_only_access?

    @show_aged_out_of_programmes = !upload_only_access
    @show_archived_records = !upload_only_access
    @show_patient_school = !upload_only_access
    @show_vaccinated_programme_status_only = upload_only_access
    @show_patient_postcode = upload_only_access
  end

  def set_patient
    @patient =
      authorize policy_scope(Patient).includes(
                  :gp_practice,
                  :school,
                  :vaccination_records,
                  consents: %i[parent patient],
                  parent_relationships: :parent
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
end
