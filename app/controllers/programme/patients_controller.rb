# frozen_string_literal: true

require "pagy/extras/array"

class Programme::PatientsController < ApplicationController
  include Pagy::Backend
  include PatientSortingConcern

  before_action :set_programme

  def index
    patients =
      policy_scope(Patient)
        .where(
          cohort: policy_scope(Cohort).for_year_groups(@programme.year_groups)
        )
        .order_by_name
        .not_deceased
        .to_a

    sort_and_filter_patients!(patients)
    @pagy, @patients = pagy_array(patients)

    @patient_sessions =
      PatientSession
        .where(
          patient: @patients,
          session: policy_scope(Session).has_programme(@programme)
        )
        .preload_for_state
        .eager_load(:session, patient: :cohort)
        .strict_loading

    render layout: "full"
  end

  private

  def set_programme
    @programme = policy_scope(Programme).find_by!(type: params[:programme_type])
  end
end
