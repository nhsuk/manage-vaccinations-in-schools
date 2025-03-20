# frozen_string_literal: true

require "pagy/extras/array"

class Sessions::TriageController < ApplicationController
  include Pagy::Backend
  include SearchFormConcern

  before_action :set_session
  before_action :set_search_form

  layout "full"

  def show
    @statuses = TriageOutcome::STATUSES - [TriageOutcome::NOT_REQUIRED]

    scope =
      @form.apply_to_scope(
        @session.patient_sessions.preload_for_status.in_programmes(
          @session.programmes
        )
      )

    @outcomes = Outcomes.new(patient_sessions: scope)

    filtered_scope =
      scope.reject do |patient_session|
        patient_session.programmes.all? do |programme|
          @outcomes.triage.not_required?(patient_session.patient, programme:)
        end
      end

    patient_sessions = @form.apply_outcomes(filtered_scope, outcomes: @outcomes)

    if patient_sessions.is_a?(Array)
      @pagy, @patient_sessions = pagy_array(patient_sessions)
    else
      @pagy, @patient_sessions = pagy(patient_sessions)
    end
  end

  private

  def set_session
    @session =
      policy_scope(Session).includes(:programmes).find_by!(
        slug: params[:session_slug]
      )
  end
end
