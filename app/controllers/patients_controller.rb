# frozen_string_literal: true

class PatientsController < ApplicationController
  include PatientSearchFormConcern

  before_action :set_patient_search_form, only: :index
  before_action :set_patient, except: :index
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
    patient_location =
      PatientLocation.find_or_create_by!(
        patient: @patient,
        location: current_team.generic_clinic,
        academic_year: AcademicYear.pending
      )

    patient_location.search_vaccinations_from_nhs_immunisations_api

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
end
