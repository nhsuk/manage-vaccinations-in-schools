# frozen_string_literal: true

require "pagy/extras/array"

class Programme::PatientsController < ApplicationController
  include Pagy::Backend
  include PatientSortingConcern

  before_action :set_programme

  def index
    patients =
      policy_scope(Patient).where(
        cohort: policy_scope(Cohort).for_year_groups(@programme.year_groups)
      ).not_deceased

    sessions = policy_scope(Session).has_programme(@programme)

    patient_sessions =
      PatientSession
        .where(patient: patients, session: sessions)
        .preload_for_state
        .eager_load(:session, patient: :cohort)
        .order_by_name
        .strict_loading
        .to_a

    sort_and_filter_patients!(patient_sessions)
    @pagy, @patient_sessions = pagy_array(patient_sessions)

    render layout: "full"
  end

  private

  def set_programme
    @programme = policy_scope(Programme).find_by!(type: params[:programme_type])
  end
end
