# frozen_string_literal: true

class ProgrammesController < ApplicationController
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
            gillick_assessment
            triages
            vaccination_records
          ]
        )
        .order("locations.name")
        .strict_loading
  end

  private

  def set_programme
    @programme =
      policy_scope(Programme).strict_loading.find_by!(type: params[:type])
  end

  def percentage_of(numerator, denominator)
    denominator.positive? ? (numerator / denominator.to_f * 100.0).to_i : 0
  end
end
