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
    patients = policy_scope(Patient).in_programme(@programme)

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
          patient_sessions: [
            :gillick_assessments,
            :triages,
            :vaccination_records,
            { consents: :parent }
          ]
        )
        .order("locations.name")
  end

  def patients
    patients = policy_scope(Patient).in_programme(@programme).not_deceased
    sessions = policy_scope(Session).has_programme(@programme)

    patient_sessions =
      PatientSession
        .where(patient: patients, session: sessions)
        .eager_load(:session, patient: :cohort)
        .preload_for_status
        .order_by_name
        .to_a

    sort_and_filter_patients!(patient_sessions)
    @pagy, @patient_sessions = pagy_array(patient_sessions)
  end

  private

  def set_programme
    @programme = policy_scope(Programme).find_by!(type: params[:type])
  end
end
