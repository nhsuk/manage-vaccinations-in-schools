# frozen_string_literal: true

class Sessions::ConsentController < ApplicationController
  include PatientSearchFormConcern

  before_action :set_session
  before_action :set_patient_search_form

  layout "full"

  def show
    statuses_except_not_required =
      Patient::ConsentStatus.statuses.keys - %w[not_required]

    @statuses =
      if @session.has_multiple_vaccine_methods?
        statuses_except_not_required.flat_map do |status|
          if status == "given"
            @session.vaccine_methods.map { "given_#{it}" }
          else
            status
          end
        end
      else
        statuses_except_not_required
      end

    scope =
      @session
        .patient_locations
        .includes(patient: [:consent_statuses, { notes: :created_by }])
        .has_consent_status(
          statuses_except_not_required,
          programme: @form.programmes
        )

    patient_locations = @form.apply(scope)
    @pagy, @patient_locations = pagy(patient_locations)
  end

  private

  def set_session
    @session =
      policy_scope(Session).includes(programmes: :vaccines).find_by!(
        slug: params[:session_slug]
      )
  end
end
