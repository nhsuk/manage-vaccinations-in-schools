# frozen_string_literal: true

require "pagy/extras/array"

class ProgrammesController < ApplicationController
  include Pagy::Backend
  include PatientSortingConcern

  before_action :set_programme, except: :index

  layout "full"

  def index
    @programmes = policy_scope(Programme).includes(:active_vaccines)
  end

  def show
    patients =
      policy_scope(Patient).where(
        cohort: policy_scope(Cohort).for_year_groups(@programme.year_groups)
      )

    @patients_count = patients.count
    @vaccinations_count = policy_scope(VaccinationRecord).count
    @consent_notifications_count =
      @programme.consent_notifications.where(patient: patients).count
    @consents =
      policy_scope(Consent).where(patient: patients, programme: @programme)
  end

  def sessions
    @sessions =
      policy_scope(Session)
        .has_programme(@programme)
        .for_current_academic_year
        .eager_load(:location)
        .preload(
          :session_dates,
          patient_sessions: %i[
            consents
            gillick_assessments
            triages
            vaccination_records
          ]
        )
        .order("locations.name")
        .strict_loading
  end

  def patients
    cohorts = policy_scope(Cohort).for_year_groups(@programme.year_groups)

    patients = policy_scope(Patient).where(cohort: cohorts).not_deceased

    sessions = policy_scope(Session).has_programme(@programme)

    patient_sessions =
      PatientSession
        .where(patient: patients, session: sessions)
        .eager_load(:session, patient: :cohort)
        .preload_for_state
        .order_by_name
        .strict_loading
        .to_a

    sort_and_filter_patients!(patient_sessions)
    @pagy, @patient_sessions = pagy_array(patient_sessions)
  end

  private

  def set_programme
    @programme =
      policy_scope(Programme).strict_loading.find_by!(type: params[:type])
  end
end
