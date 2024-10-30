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

    sessions = policy_scope(Session).has_programme(@programme)

    @patients_count = patients.count
    @sessions_count = sessions.count
    @vaccinations_count =
      policy_scope(VaccinationRecord)
        .administered
        .where(programme: @programme)
        .count

    @consent_notifications_count =
      @programme.consent_notifications.where(patient: patients).count

    @consents =
      policy_scope(Consent).where(patient: patients, programme: @programme)

    stats =
      PatientSessionStats.new(
        PatientSession
          .where(patient: patients, session: sessions)
          .preload_for_state
          .strict_loading
      )

    @consent_given_percentage =
      percentage_of(stats[:with_consent_given], @consents.count)
    @responses_received_and_triaged_percentage =
      percentage_of(
        @patients_count - (stats[:without_a_response] + stats[:needing_triage]),
        @patients_count
      )
  end

  def sessions
    @sessions =
      policy_scope(Session)
        .has_programme(@programme)
        .eager_load(:location)
        .preload(
          :session_dates,
          patient_sessions: %i[
            consents
            latest_gillick_assessment
            latest_vaccination_record
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
